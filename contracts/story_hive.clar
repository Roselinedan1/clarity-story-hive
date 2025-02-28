;; StoryHive - Collaborative Storytelling Platform

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-authorized (err u100))
(define-constant err-invalid-story (err u101))
(define-constant err-already-voted (err u102))
(define-constant err-no-proposal (err u103))
(define-constant err-invalid-category (err u104))
(define-constant err-story-limit-reached (err u105))
(define-constant err-proposal-limit-reached (err u106))
(define-constant err-story-inactive (err u107))
(define-constant err-content-too-long (err u108))

;; Data Variables
(define-data-var next-story-id uint u0)
(define-data-var next-proposal-id uint u0)
(define-data-var max-stories uint u1000)
(define-data-var max-proposals uint u5000)

;; Data Maps
(define-map stories 
    uint 
    {
        title: (string-ascii 100),
        creator: principal,
        episode-count: uint,
        premium: bool,
        earnings: uint,
        category: (string-ascii 20),
        reward-pool: uint,
        likes: uint,
        status: (string-ascii 10)  ;; "active" or "completed"
    }
)

(define-map proposals
    uint 
    {
        story-id: uint,
        author: principal,
        content: (string-utf8 1000),
        votes: uint,
        status: (string-ascii 20),
        reward-claimed: bool,
        submission-height: uint
    }
)

;; [Previous maps remain unchanged]

;; Create new story series
(define-public (create-story (title (string-ascii 100)) (premium bool) (category (string-ascii 20)))
    (let
        ((story-id (var-get next-story-id)))
        (asserts! (< story-id (var-get max-stories)) err-story-limit-reached)
        (asserts! (default-to false (map-get? categories category)) err-invalid-category)
        (map-set stories story-id {
            title: title,
            creator: tx-sender,
            episode-count: u0,
            premium: premium,
            earnings: u0,
            category: category,
            reward-pool: u0,
            likes: u0,
            status: "active"
        })
        (var-set next-story-id (+ story-id u1))
        (ok story-id)
    )
)

;; Submit episode proposal
(define-public (submit-proposal (story-id uint) (content (string-utf8 1000)))
    (let
        ((proposal-id (var-get next-proposal-id))
         (story (unwrap! (map-get? stories story-id) err-invalid-story)))
        (asserts! (< proposal-id (var-get max-proposals)) err-proposal-limit-reached)
        (asserts! (is-eq (get status story) "active") err-story-inactive)
        (asserts! (<= (len content) u1000) err-content-too-long)
        (map-set proposals proposal-id {
            story-id: story-id,
            author: tx-sender,
            content: content,
            votes: u0,
            status: "pending",
            reward-claimed: false,
            submission-height: block-height
        })
        (var-set next-proposal-id (+ proposal-id u1))
        (ok proposal-id)
    )
)

;; Reject proposal
(define-public (reject-proposal (proposal-id uint))
    (let
        ((proposal (unwrap! (map-get? proposals proposal-id) err-no-proposal))
         (story (unwrap! (map-get? stories (get story-id proposal)) err-invalid-story)))
        (asserts! (is-eq (get creator story) tx-sender) err-not-authorized)
        (map-set proposals proposal-id
            (merge proposal {status: "rejected"})
        )
        (ok true)
    )
)

;; Complete story
(define-public (complete-story (story-id uint))
    (let
        ((story (unwrap! (map-get? stories story-id) err-invalid-story)))
        (asserts! (is-eq (get creator story) tx-sender) err-not-authorized)
        (map-set stories story-id
            (merge story {status: "completed"})
        )
        (ok true)
    )
)

;; [Previous functions remain unchanged]

;; New read-only functions
(define-read-only (get-story-proposals (story-id uint))
    (ok (filter proposals story-id))
)

(define-read-only (get-story-status (story-id uint))
    (ok (get status (default-to {status: "none"} (map-get? stories story-id))))
)
