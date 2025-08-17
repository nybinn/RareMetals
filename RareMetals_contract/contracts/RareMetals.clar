
;; title: RareMetals
;; version: 1.0.0
;; summary: Synthetic assets smart contract for rare earth elements and strategic materials
;; description: Creates synthetic exposure to traditional rare metal assets with minting, burning, and price feed management

;; traits
(define-trait price-feed-trait
  (
    (get-price ((buff 32)) (response uint uint))
  )
)

;; token definitions
(define-fungible-token rare-metals-synthetic)

;; constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_INSUFFICIENT_BALANCE (err u101))
(define-constant ERR_INVALID_AMOUNT (err u102))
(define-constant ERR_METAL_NOT_FOUND (err u103))
(define-constant ERR_PRICE_FEED_ERROR (err u104))
(define-constant ERR_INVALID_COLLATERAL_RATIO (err u105))
(define-constant ERR_PAUSED (err u106))

;; Minimum collateral ratio (150% = 150)
(define-constant MIN_COLLATERAL_RATIO u150)

;; data vars
(define-data-var contract-paused bool false)
(define-data-var total-collateral uint u0)
(define-data-var price-feed-contract (optional principal) none)

;; data maps
;; Supported rare metals with their symbols
(define-map supported-metals 
  (buff 32)
  {
    name: (string-ascii 64),
    symbol: (string-ascii 8),
    active: bool,
    price-per-gram: uint ;; Price in micro-STX per gram
  }
)

;; User positions tracking collateral and synthetic tokens
(define-map user-positions
  principal
  {
    stx-collateral: uint,
    synthetic-tokens: uint,
    metal-exposure: (buff 32) ;; Which metal they have exposure to
  }
)

;; Price history for metals (last 10 prices)
(define-map price-history
  (buff 32)
  (list 10 uint)
)

;; Authorized price feed operators
(define-map authorized-oracles principal bool)

;; public functions

;; Initialize supported rare metals
(define-public (initialize-metals)
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (map-set supported-metals 0x4c49544849554d ;; "LITHIUM" as hex buffer
      {
        name: "Lithium",
        symbol: "Li",
        active: true,
        price-per-gram: u50000 ;; 50,000 micro-STX per gram
      })
    (map-set supported-metals 0x434f42414c54 ;; "COBALT" as hex buffer
      {
        name: "Cobalt",
        symbol: "Co", 
        active: true,
        price-per-gram: u30000
      })
    (map-set supported-metals 0x4e454f44594d49554d ;; "NEODYMIUM" as hex buffer
      {
        name: "Neodymium",
        symbol: "Nd",
        active: true,
        price-per-gram: u80000
      })
    (map-set supported-metals 0x504c4154494e554d ;; "PLATINUM" as hex buffer
      {
        name: "Platinum",
        symbol: "Pt",
        active: true,
        price-per-gram: u32000000 ;; 32M micro-STX per gram
      })
    (map-set supported-metals 0x50414c4c414449554d ;; "PALLADIUM" as hex buffer
      {
        name: "Palladium",
        symbol: "Pd",
        active: true,
        price-per-gram: u72000000
      })
    (ok true)
  )
)

;; Add or update a supported metal (only owner)
(define-public (add-metal (metal-id (buff 32)) (name (string-ascii 64)) (symbol (string-ascii 8)) (price uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (> price u0) ERR_INVALID_AMOUNT)
    (map-set supported-metals metal-id {
      name: name,
      symbol: symbol,
      active: true,
      price-per-gram: price
    })
    (ok true)
  )
)

;; Mint synthetic tokens against STX collateral
(define-public (mint-synthetic (metal-id (buff 32)) (stx-amount uint) (synthetic-amount uint))
  (let (
    (metal-info (unwrap! (map-get? supported-metals metal-id) ERR_METAL_NOT_FOUND))
    (current-position (default-to {stx-collateral: u0, synthetic-tokens: u0, metal-exposure: 0x4e4f4e45} ;; "NONE" as hex buffer
                                 (map-get? user-positions tx-sender)))
    (required-collateral (calculate-required-collateral metal-id synthetic-amount))
  )
    (asserts! (not (var-get contract-paused)) ERR_PAUSED)
    (asserts! (get active metal-info) ERR_METAL_NOT_FOUND)
    (asserts! (> stx-amount u0) ERR_INVALID_AMOUNT)
    (asserts! (> synthetic-amount u0) ERR_INVALID_AMOUNT)
    (asserts! (>= stx-amount required-collateral) ERR_INVALID_COLLATERAL_RATIO)
    
    ;; Transfer STX as collateral
    (try! (stx-transfer? stx-amount tx-sender (as-contract tx-sender)))
    
    ;; Mint synthetic tokens
    (try! (ft-mint? rare-metals-synthetic synthetic-amount tx-sender))
    
    ;; Update user position
    (map-set user-positions tx-sender {
      stx-collateral: (+ (get stx-collateral current-position) stx-amount),
      synthetic-tokens: (+ (get synthetic-tokens current-position) synthetic-amount),
      metal-exposure: metal-id
    })
    
    ;; Update total collateral
    (var-set total-collateral (+ (var-get total-collateral) stx-amount))
    
    (ok synthetic-amount)
  )
)

;; Burn synthetic tokens to reclaim STX collateral
(define-public (burn-synthetic (synthetic-amount uint))
  (let (
    (user-position (unwrap! (map-get? user-positions tx-sender) ERR_INSUFFICIENT_BALANCE))
    (user-synthetic-balance (get synthetic-tokens user-position))
    (user-collateral (get stx-collateral user-position))
    (collateral-to-return (/ (* user-collateral synthetic-amount) user-synthetic-balance))
  )
    (asserts! (not (var-get contract-paused)) ERR_PAUSED)
    (asserts! (> synthetic-amount u0) ERR_INVALID_AMOUNT)
    (asserts! (>= user-synthetic-balance synthetic-amount) ERR_INSUFFICIENT_BALANCE)
    
    ;; Burn synthetic tokens
    (try! (ft-burn? rare-metals-synthetic synthetic-amount tx-sender))
    
    ;; Transfer STX collateral back
    (try! (as-contract (stx-transfer? collateral-to-return tx-sender tx-sender)))
    
    ;; Update user position
    (map-set user-positions tx-sender {
      stx-collateral: (- user-collateral collateral-to-return),
      synthetic-tokens: (- user-synthetic-balance synthetic-amount),
      metal-exposure: (get metal-exposure user-position)
    })
    
    ;; Update total collateral
    (var-set total-collateral (- (var-get total-collateral) collateral-to-return))
    
    (ok collateral-to-return)
  )
)

;; Update metal price (only authorized oracles)
(define-public (update-price (metal-id (buff 32)) (new-price uint))
  (let (
    (metal-info (unwrap! (map-get? supported-metals metal-id) ERR_METAL_NOT_FOUND))
    (current-history (default-to (list) (map-get? price-history metal-id)))
  )
    (asserts! (default-to false (map-get? authorized-oracles tx-sender)) ERR_UNAUTHORIZED)
    (asserts! (> new-price u0) ERR_INVALID_AMOUNT)
    
    ;; Update metal price
    (map-set supported-metals metal-id (merge metal-info {price-per-gram: new-price}))
    
    ;; Update price history (keep last 10 prices)
    (map-set price-history metal-id 
      (unwrap-panic (as-max-len? (append current-history new-price) u10)))
    
    (ok true)
  )
)

;; Add authorized oracle (only owner)
(define-public (add-oracle (oracle-address principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (map-set authorized-oracles oracle-address true)
    (ok true)
  )
)

;; Remove authorized oracle (only owner)  
(define-public (remove-oracle (oracle-address principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (map-delete authorized-oracles oracle-address)
    (ok true)
  )
)

;; Pause/unpause contract (only owner)
(define-public (set-contract-paused (paused bool))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (var-set contract-paused paused)
    (ok true)
  )
)

;; read only functions

;; Get metal information
(define-read-only (get-metal-info (metal-id (buff 32)))
  (map-get? supported-metals metal-id)
)

;; Get user position
(define-read-only (get-user-position (user principal))
  (map-get? user-positions user)
)

;; Get price history for a metal
(define-read-only (get-price-history (metal-id (buff 32)))
  (map-get? price-history metal-id)
)

;; Calculate required collateral for synthetic amount
(define-read-only (calculate-required-collateral (metal-id (buff 32)) (synthetic-amount uint))
  (let (
    (metal-info (unwrap! (map-get? supported-metals metal-id) u0))
    (metal-price (get price-per-gram metal-info))
    (collateral-value (* synthetic-amount metal-price))
  )
    (/ (* collateral-value MIN_COLLATERAL_RATIO) u100)
  )
)

;; Get current collateral ratio for user
(define-read-only (get-collateral-ratio (user principal))
  (let (
    (position (unwrap! (map-get? user-positions user) u0))
    (collateral (get stx-collateral position))
    (synthetic-tokens (get synthetic-tokens position))
    (metal-id (get metal-exposure position))
    (metal-info (unwrap! (map-get? supported-metals metal-id) u0))
    (metal-price (get price-per-gram metal-info))
    (synthetic-value (* synthetic-tokens metal-price))
  )
    (if (is-eq synthetic-value u0)
      u0
      (/ (* collateral u100) synthetic-value)
    )
  )
)

;; Check if oracle is authorized
(define-read-only (is-authorized-oracle (oracle principal))
  (default-to false (map-get? authorized-oracles oracle))
)

;; Get contract status
(define-read-only (get-contract-status)
  {
    paused: (var-get contract-paused),
    total-collateral: (var-get total-collateral),
    total-supply: (ft-get-supply rare-metals-synthetic)
  }
)

;; Get synthetic token balance
(define-read-only (get-balance (user principal))
  (ft-get-balance rare-metals-synthetic user)
)

;; private functions

;; Initialize contract (called once)
(define-private (init)
  (begin
    (map-set authorized-oracles CONTRACT_OWNER true)
    true
  )
)

;; Initialize the contract
(init)
