;; StoryHive - Collaborative Storytelling Platform

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-authorized (err u100))
(define-constant err-invalid-story (err u101))
(define-constant err-already-voted (err u102))
(define-constant err-no-proposal (err u103))

;; Data Variables
(define-data-var next-story-id uint u0)
(define-data-var next-proposal-id uint u0)

;; Data Maps
(define-map stories 
    uint 
    {
        title: (string-ascii 100),
        creator: principal,
        episode-count: uint,
        premium: bool,
        earnings: uint
    }
)

(define-map proposals
    uint 
    {
        story-id: uint,
        author: principal,
        content: (string-utf8 1000),
        votes: uint,
        status: (string-ascii 20)
    }
)

(define-map user-votes
    {user: principal, proposal: uint}
    bool
)

(define-map story-access
    {user: principal, story: uint}
    bool
)

;; Create new story series
(define-public (create-story (title (string-ascii 100)) (premium bool))
    (let
        ((story-id (var-get next-story-id)))
        (map-set stories story-id {
            title: title,
            creator: tx-sender,
            episode-count: u0,
            premium: premium,
            earnings: u0
        })
        (var-set next-story-id (+ story-id u1))
        (ok story-id)
    )
)

;; Submit episode proposal
(define-public (submit-proposal (story-id uint) (content (string-utf8 1000)))
    (let
        ((proposal-id (var-get next-proposal-id)))
        (asserts! (is-some (map-get? stories story-id)) err-invalid-story)
        (map-set proposals proposal-id {
            story-id: story-id,
            author: tx-sender,
            content: content,
            votes: u0,
            status: "pending"
        })
        (var-set next-proposal-id (+ proposal-id u1))
        (ok proposal-id)
    )
)

;; Vote on proposal
(define-public (vote-proposal (proposal-id uint))
    (let
        ((proposal (unwrap! (map-get? proposals proposal-id) err-no-proposal))
         (vote-key {user: tx-sender, proposal: proposal-id}))
        (asserts! (is-none (map-get? user-votes vote-key)) err-already-voted)
        (map-set user-votes vote-key true)
        (map-set proposals proposal-id 
            (merge proposal {votes: (+ (get votes proposal) u1)})
        )
        (ok true)
    )
)

;; Accept proposal and add as new episode
(define-public (accept-proposal (proposal-id uint))
    (let
        ((proposal (unwrap! (map-get? proposals proposal-id) err-no-proposal))
         (story (unwrap! (map-get? stories (get story-id proposal)) err-invalid-story)))
        (asserts! (is-eq (get creator story) tx-sender) err-not-authorized)
        (map-set stories (get story-id proposal)
            (merge story {episode-count: (+ (get episode-count story) u1)})
        )
        (map-set proposals proposal-id
            (merge proposal {status: "accepted"})
        )
        (ok true)
    )
)

;; Purchase access to premium story
(define-public (purchase-access (story-id uint))
    (let
        ((story (unwrap! (map-get? stories story-id) err-invalid-story)))
        (asserts! (get premium story) err-not-authorized)
        (map-set story-access {user: tx-sender, story: story-id} true)
        (map-set stories story-id
            (merge story {earnings: (+ (get earnings story) u1)})
        )
        (ok true)
    )
)

;; Read-only functions
(define-read-only (get-story (story-id uint))
    (ok (map-get? stories story-id))
)

(define-read-only (get-proposal (proposal-id uint))
    (ok (map-get? proposals proposal-id))
)

(define-read-only (check-story-access (story-id uint) (user principal))
    (ok (default-to false (map-get? story-access {user: user, story: story-id})))
)