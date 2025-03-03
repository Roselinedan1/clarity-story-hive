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
(define-constant err-contract-paused (err u109))
(define-constant err-cooldown-active (err u110))

;; Data Variables
(define-data-var next-story-id uint u0)
(define-data-var next-proposal-id uint u0)
(define-data-var max-stories uint u1000)
(define-data-var max-proposals uint u5000)
(define-data-var contract-paused bool false)
(define-data-var proposal-cooldown uint u100) ;; blocks between proposals

;; Helper Functions
(define-private (is-contract-owner)
    (is-eq tx-sender contract-owner))

(define-private (check-not-paused)
    (asserts! (not (var-get contract-paused)) err-contract-paused))

(define-private (check-proposal-cooldown (author principal))
    (let ((last-proposal (default-to u0 (map-get? user-last-proposal author))))
        (asserts! (>= block-height (+ last-proposal (var-get proposal-cooldown))) 
                 err-cooldown-active)))

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
        status: (string-ascii 10),
        version: uint
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
        submission-height: uint,
        review-period-end: uint
    }
)

(define-map user-last-proposal
    principal
    uint)

;; Admin Functions
(define-public (toggle-contract-pause)
    (begin
        (asserts! (is-contract-owner) err-not-authorized)
        (ok (var-set contract-paused (not (var-get contract-paused))))
    ))

(define-public (set-proposal-cooldown (new-cooldown uint))
    (begin
        (asserts! (is-contract-owner) err-not-authorized)
        (ok (var-set proposal-cooldown new-cooldown))
    ))

;; [Previous functions with added security checks]
(define-public (create-story (title (string-ascii 100)) (premium bool) (category (string-ascii 20)))
    (begin
        (check-not-paused)
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
                status: "active",
                version: u1
            })
            (var-set next-story-id (+ story-id u1))
            (ok story-id)
        )
    ))

[... remaining functions with similar security enhancements ...]
