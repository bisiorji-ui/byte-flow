;; ByteFlow - Blockchain Roguelike Dungeon Crawler
;; A simple implementation of character NFTs with evolution mechanics

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-token-owner (err u101))
(define-constant err-character-not-found (err u102))
(define-constant err-insufficient-balance (err u103))
(define-constant err-already-exists (err u104))

;; Data Variables
(define-data-var last-token-id uint u0)
(define-data-var evolution-cost uint u100)
(define-data-var dungeon-reward uint u50)

;; Data Maps
(define-map characters
    uint
    {
        owner: principal,
        level: uint,
        strength: uint,
        agility: uint,
        intelligence: uint,
        evolution-count: uint,
        dungeons-completed: uint,
        created-at: uint
    }
)

(define-map character-metadata
    uint
    {
        name: (string-ascii 50),
        dna-hash: (string-ascii 64)
    }
)

(define-map user-balances
    principal
    uint
)

(define-map governance-tokens
    principal
    uint
)

(define-map staked-characters
    uint
    {
        staker: principal,
        stake-amount: uint,
        stake-block: uint
    }
)

;; Private Functions
(define-private (get-next-token-id)
    (let
        ((current-id (var-get last-token-id)))
        (var-set last-token-id (+ current-id u1))
        current-id
    )
)

;; Read-Only Functions
(define-read-only (get-character (token-id uint))
    (map-get? characters token-id)
)

(define-read-only (get-character-metadata (token-id uint))
    (map-get? character-metadata token-id)
)

(define-read-only (get-user-balance (user principal))
    (default-to u0 (map-get? user-balances user))
)

(define-read-only (get-governance-balance (user principal))
    (default-to u0 (map-get? governance-tokens user))
)

(define-read-only (get-character-owner (token-id uint))
    (match (map-get? characters token-id)
        character (ok (get owner character))
        (err err-character-not-found)
    )
)

(define-read-only (get-staked-info (token-id uint))
    (map-get? staked-characters token-id)
)

(define-read-only (get-last-token-id)
    (var-get last-token-id)
)

;; Public Functions

;; Mint a new character NFT
(define-public (mint-character (name (string-ascii 50)) (dna-hash (string-ascii 64)))
    (let
        (
            (token-id (get-next-token-id))
            (sender tx-sender)
        )
        (map-set characters token-id
            {
                owner: sender,
                level: u1,
                strength: u10,
                agility: u10,
                intelligence: u10,
                evolution-count: u0,
                dungeons-completed: u0,
                created-at: block-height
            }
        )
        (map-set character-metadata token-id
            {
                name: name,
                dna-hash: dna-hash
            }
        )
        (ok token-id)
    )
)

;; Transfer character to another user
(define-public (transfer-character (token-id uint) (recipient principal))
    (let
        (
            (character (unwrap! (map-get? characters token-id) err-character-not-found))
            (sender tx-sender)
        )
        (asserts! (is-eq sender (get owner character)) err-not-token-owner)
        (map-set characters token-id
            (merge character {owner: recipient})
        )
        (ok true)
    )
)

;; Evolve character by spending tokens
(define-public (evolve-character (token-id uint) (stat-type (string-ascii 20)))
    (let
        (
            (character (unwrap! (map-get? characters token-id) err-character-not-found))
            (sender tx-sender)
            (cost (var-get evolution-cost))
            (balance (get-user-balance sender))
        )
        (asserts! (is-eq sender (get owner character)) err-not-token-owner)
        (asserts! (>= balance cost) err-insufficient-balance)
        
        ;; Deduct evolution cost
        (map-set user-balances sender (- balance cost))
        
        ;; Update character stats based on stat-type
        (map-set characters token-id
            (merge character
                {
                    level: (+ (get level character) u1),
                    strength: (if (is-eq stat-type "strength") 
                                (+ (get strength character) u5) 
                                (get strength character)),
                    agility: (if (is-eq stat-type "agility") 
                               (+ (get agility character) u5) 
                               (get agility character)),
                    intelligence: (if (is-eq stat-type "intelligence") 
                                    (+ (get intelligence character) u5) 
                                    (get intelligence character)),
                    evolution-count: (+ (get evolution-count character) u1)
                }
            )
        )
        (ok true)
    )
)

;; Complete dungeon and earn rewards
(define-public (complete-dungeon (token-id uint))
    (let
        (
            (character (unwrap! (map-get? characters token-id) err-character-not-found))
            (sender tx-sender)
            (reward (var-get dungeon-reward))
            (current-balance (get-user-balance sender))
            (current-governance (get-governance-balance sender))
        )
        (asserts! (is-eq sender (get owner character)) err-not-token-owner)
        
        ;; Update dungeon completion count
        (map-set characters token-id
            (merge character 
                {dungeons-completed: (+ (get dungeons-completed character) u1)}
            )
        )
        
        ;; Award tokens
        (map-set user-balances sender (+ current-balance reward))
        
        ;; Award governance tokens (10% of reward)
        (map-set governance-tokens sender (+ current-governance (/ reward u10)))
        
        (ok reward)
    )
)

;; Stake character for passive income
(define-public (stake-character (token-id uint) (amount uint))
    (let
        (
            (character (unwrap! (map-get? characters token-id) err-character-not-found))
            (sender tx-sender)
            (balance (get-user-balance sender))
        )
        (asserts! (is-eq sender (get owner character)) err-not-token-owner)
        (asserts! (>= balance amount) err-insufficient-balance)
        
        ;; Deduct stake amount
        (map-set user-balances sender (- balance amount))
        
        ;; Record stake
        (map-set staked-characters token-id
            {
                staker: sender,
                stake-amount: amount,
                stake-block: block-height
            }
        )
        (ok true)
    )
)

;; Unstake character and claim rewards
(define-public (unstake-character (token-id uint))
    (let
        (
            (stake-info (unwrap! (map-get? staked-characters token-id) err-character-not-found))
            (sender tx-sender)
            (stake-amount (get stake-amount stake-info))
            (blocks-staked (- block-height (get stake-block stake-info)))
            (reward (/ (* stake-amount blocks-staked) u1000))
            (current-balance (get-user-balance sender))
        )
        (asserts! (is-eq sender (get staker stake-info)) err-not-token-owner)
        
        ;; Return stake plus reward
        (map-set user-balances sender (+ current-balance (+ stake-amount reward)))
        
        ;; Remove stake record
        (map-delete staked-characters token-id)
        
        (ok (+ stake-amount reward))
    )
)

;; Admin function to set evolution cost
(define-public (set-evolution-cost (new-cost uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (var-set evolution-cost new-cost)
        (ok true)
    )
)

;; Admin function to set dungeon reward
(define-public (set-dungeon-reward (new-reward uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (var-set dungeon-reward new-reward)
        (ok true)
    )
)

;; Grant tokens to user (for testing/admin purposes)
(define-public (grant-tokens (recipient principal) (amount uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (map-set user-balances recipient 
            (+ (get-user-balance recipient) amount))
        (ok true)
    )
)
