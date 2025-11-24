(define-fungible-token carbon-offset-token)

(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-OWNER-ONLY (err u100))
(define-constant ERR-NOT-FOUND (err u101))
(define-constant ERR-INSUFFICIENT-FUNDS (err u102))
(define-constant ERR-ALREADY-EXISTS (err u103))
(define-constant ERR-INVALID-AMOUNT (err u104))
(define-constant ERR-INVALID-PRICE (err u105))
(define-constant ERR-NOT-AUTHORIZED (err u106))
(define-constant ERR-EXPIRED (err u107))

(define-data-var next-offset-id uint u1)
(define-data-var marketplace-fee-rate uint u250)

(define-map carbon-offsets
  uint
  {
    issuer: principal,
    project-name: (string-ascii 50),
    co2-amount: uint,
    verification-standard: (string-ascii 30),
    vintage-year: uint,
    price-per-token: uint,
    total-supply: uint,
    available-supply: uint,
    is-verified: bool,
    expiry-block: uint
  }
)

(define-map user-balances
  { user: principal, offset-id: uint }
  uint
)

(define-map retired-balances
  { user: principal, offset-id: uint }
  uint
)

(define-map total-retired-by-offset
  uint
  uint
)

(define-map marketplace-listings
  uint
  {
    seller: principal,
    offset-id: uint,
    quantity: uint,
    price-per-token: uint,
    expiry-block: uint,
    is-active: bool
  }
)

(define-data-var next-listing-id uint u1)

(define-map verified-issuers principal bool)

(define-public (issue-carbon-offset
  (project-name (string-ascii 50))
  (co2-amount uint)
  (verification-standard (string-ascii 30))
  (vintage-year uint)
  (price-per-token uint)
  (total-supply uint)
  (expiry-block uint)
)
  (let
    (
      (offset-id (var-get next-offset-id))
      (issuer tx-sender)
    )
    (asserts! (> co2-amount u0) ERR-INVALID-AMOUNT)
    (asserts! (> price-per-token u0) ERR-INVALID-PRICE)
    (asserts! (> total-supply u0) ERR-INVALID-AMOUNT)
    (asserts! (> expiry-block stacks-block-height) ERR-EXPIRED)
    
    (map-set carbon-offsets offset-id {
      issuer: issuer,
      project-name: project-name,
      co2-amount: co2-amount,
      verification-standard: verification-standard,
      vintage-year: vintage-year,
      price-per-token: price-per-token,
      total-supply: total-supply,
      available-supply: total-supply,
      is-verified: (default-to false (map-get? verified-issuers issuer)),
      expiry-block: expiry-block
    })
    
    (map-set user-balances { user: issuer, offset-id: offset-id } total-supply)
    (var-set next-offset-id (+ offset-id u1))
    (ok offset-id)
  )
)

(define-public (verify-issuer (issuer principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-OWNER-ONLY)
    (map-set verified-issuers issuer true)
    (ok true)
  )
)

(define-public (purchase-offset (offset-id uint) (quantity uint))
  (let
    (
      (offset-data (unwrap! (map-get? carbon-offsets offset-id) ERR-NOT-FOUND))
      (buyer tx-sender)
      (issuer (get issuer offset-data))
      (price-per-token (get price-per-token offset-data))
      (available-supply (get available-supply offset-data))
      (total-cost (* quantity price-per-token))
      (fee (/ (* total-cost (var-get marketplace-fee-rate)) u10000))
      (issuer-payment (- total-cost fee))
      (current-balance (default-to u0 (map-get? user-balances { user: buyer, offset-id: offset-id })))
    )
    (asserts! (> quantity u0) ERR-INVALID-AMOUNT)
    (asserts! (>= available-supply quantity) ERR-INSUFFICIENT-FUNDS)
    (asserts! (<= stacks-block-height (get expiry-block offset-data)) ERR-EXPIRED)
    
    (try! (stx-transfer? total-cost buyer issuer))
    
    (map-set carbon-offsets offset-id
      (merge offset-data { available-supply: (- available-supply quantity) })
    )
    
    (map-set user-balances { user: buyer, offset-id: offset-id }
      (+ current-balance quantity)
    )
    
    (try! (ft-mint? carbon-offset-token quantity buyer))
    (ok true)
  )
)

(define-public (create-listing
  (offset-id uint)
  (quantity uint)
  (price-per-token uint)
  (expiry-block uint)
)
  (let
    (
      (listing-id (var-get next-listing-id))
      (seller tx-sender)
      (user-balance (default-to u0 (map-get? user-balances { user: seller, offset-id: offset-id })))
    )
    (asserts! (> quantity u0) ERR-INVALID-AMOUNT)
    (asserts! (> price-per-token u0) ERR-INVALID-PRICE)
    (asserts! (>= user-balance quantity) ERR-INSUFFICIENT-FUNDS)
    (asserts! (> expiry-block stacks-block-height) ERR-EXPIRED)
    
    (map-set marketplace-listings listing-id {
      seller: seller,
      offset-id: offset-id,
      quantity: quantity,
      price-per-token: price-per-token,
      expiry-block: expiry-block,
      is-active: true
    })
    
    (map-set user-balances { user: seller, offset-id: offset-id }
      (- user-balance quantity)
    )
    
    (var-set next-listing-id (+ listing-id u1))
    (ok listing-id)
  )
)

(define-public (purchase-from-listing (listing-id uint) (quantity uint))
  (let
    (
      (listing-data (unwrap! (map-get? marketplace-listings listing-id) ERR-NOT-FOUND))
      (buyer tx-sender)
      (seller (get seller listing-data))
      (offset-id (get offset-id listing-data))
      (available-quantity (get quantity listing-data))
      (price-per-token (get price-per-token listing-data))
      (total-cost (* quantity price-per-token))
      (fee (/ (* total-cost (var-get marketplace-fee-rate)) u10000))
      (seller-payment (- total-cost fee))
      (buyer-balance (default-to u0 (map-get? user-balances { user: buyer, offset-id: offset-id })))
    )
    (asserts! (> quantity u0) ERR-INVALID-AMOUNT)
    (asserts! (get is-active listing-data) ERR-NOT-FOUND)
    (asserts! (>= available-quantity quantity) ERR-INSUFFICIENT-FUNDS)
    (asserts! (<= stacks-block-height (get expiry-block listing-data)) ERR-EXPIRED)
    
    (try! (stx-transfer? total-cost buyer seller))
    
    (if (is-eq quantity available-quantity)
      (map-set marketplace-listings listing-id
        (merge listing-data { is-active: false, quantity: u0 })
      )
      (map-set marketplace-listings listing-id
        (merge listing-data { quantity: (- available-quantity quantity) })
      )
    )
    
    (map-set user-balances { user: buyer, offset-id: offset-id }
      (+ buyer-balance quantity)
    )
    
    (ok true)
  )
)

(define-public (retire-offset (offset-id uint) (quantity uint))
  (let
    (
      (user tx-sender)
      (user-balance (default-to u0 (map-get? user-balances { user: user, offset-id: offset-id })))
      (current-retired (default-to u0 (map-get? retired-balances { user: user, offset-id: offset-id })))
      (offset-total-retired (default-to u0 (map-get? total-retired-by-offset offset-id)))
    )
    (asserts! (> quantity u0) ERR-INVALID-AMOUNT)
    (asserts! (>= user-balance quantity) ERR-INSUFFICIENT-FUNDS)
    
    (map-set user-balances { user: user, offset-id: offset-id }
      (- user-balance quantity)
    )
    
    (map-set retired-balances { user: user, offset-id: offset-id }
      (+ current-retired quantity)
    )
    
    (map-set total-retired-by-offset offset-id
      (+ offset-total-retired quantity)
    )
    
    (try! (ft-burn? carbon-offset-token quantity user))
    (ok true)
  )
)

(define-public (cancel-listing (listing-id uint))
  (let
    (
      (listing-data (unwrap! (map-get? marketplace-listings listing-id) ERR-NOT-FOUND))
      (seller (get seller listing-data))
      (offset-id (get offset-id listing-data))
      (quantity (get quantity listing-data))
      (current-balance (default-to u0 (map-get? user-balances { user: seller, offset-id: offset-id })))
    )
    (asserts! (is-eq tx-sender seller) ERR-NOT-AUTHORIZED)
    (asserts! (get is-active listing-data) ERR-NOT-FOUND)
    
    (map-set marketplace-listings listing-id
      (merge listing-data { is-active: false })
    )
    
    (map-set user-balances { user: seller, offset-id: offset-id }
      (+ current-balance quantity)
    )
    
    (ok true)
  )
)

(define-public (set-marketplace-fee (new-rate uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-OWNER-ONLY)
    (asserts! (<= new-rate u1000) ERR-INVALID-AMOUNT)
    (var-set marketplace-fee-rate new-rate)
    (ok true)
  )
)

(define-read-only (get-offset (offset-id uint))
  (map-get? carbon-offsets offset-id)
)

(define-read-only (get-user-balance (user principal) (offset-id uint))
  (default-to u0 (map-get? user-balances { user: user, offset-id: offset-id }))
)

(define-read-only (get-listing (listing-id uint))
  (map-get? marketplace-listings listing-id)
)

(define-read-only (get-marketplace-fee-rate)
  (var-get marketplace-fee-rate)
)

(define-read-only (is-verified-issuer (issuer principal))
  (default-to false (map-get? verified-issuers issuer))
)

(define-read-only (get-retired-balance (user principal) (offset-id uint))
  (default-to u0 (map-get? retired-balances { user: user, offset-id: offset-id }))
)

(define-read-only (get-offset-total-retired (offset-id uint))
  (default-to u0 (map-get? total-retired-by-offset offset-id))
)

(define-read-only (get-token-balance (user principal))
  (ft-get-balance carbon-offset-token user)
)

(define-read-only (get-total-supply)
  (ft-get-supply carbon-offset-token)
)
