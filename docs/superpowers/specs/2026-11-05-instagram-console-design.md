# Instagram in the web console — design (approved 2026-11-05)

Koby runs the app's Instagram account from aieasyplate.app/admin. Claude prepares drafts
(images composed by `tools/instagram/compose.py`, captions written by hand — no Gemini, no cost);
Koby reviews, edits, approves, publishes or schedules, uploads his own posts, and reads stats and
comments. Nothing reaches Instagram without his approval in the console.

## Data
- `instagram_posts/{id}`: `type` (image | carousel | reel | story), `title` (internal), `caption`,
  `media` [{path, kind: image|video, contentType, width?, height?}], `source` (claude | upload),
  `status` draft → approved → scheduled → publishing → published | failed (`error`),
  `scheduledAt` (only while scheduled — the runner's single range query), `published`
  {mediaId, permalink, at}, `insights` {likes, comments, reach, saved, shares, views, at},
  createdAt / updatedAt / updatedBy. Admin reads (rules); written only by functions.
- `admin_config/instagram`: account summary for the console (username, user id, followers,
  token refreshedAt / expiresAt, insightsAt). `admin_config/instagram_private`: the access token,
  never readable by any client (rules exclude it like `stores_private`).
- Storage `marketing/instagram/{postId}/…`: admin-only upload (rule checks users/{uid}.permission),
  images ≤ 8 MB JPEG, video ≤ 100 MB MP4/MOV. Instagram fetches through a download-token URL the
  function adds at publish time.

## Server (`functions/adminInstagram.js`, actions through `adminPanel`)
`ig.account.get | connect | disconnect`, `ig.post.save | approve | publish | schedule | unschedule
| delete`, `ig.insights.refresh`, `ig.comments.list`, `ig.comment.reply | hide`.
Editing an approved / scheduled / failed post returns it to draft. Validation before approve and
publish: type ↔ media count and kinds, JPEG only for images, caption ≤ 2200, ≤ 30 hashtags, ≤ 20
mentions, and the creative rule (no price, plan, Premium, Pro, trial). Publishing claims the post in a
transaction (→ publishing) so it never goes out twice; a post stuck in publishing for 15 minutes
becomes failed with "check Instagram before retrying".

Runner `runInstagram` (every 5 minutes, Israel time): publish due scheduled posts; once a day refresh
insights for posts of the last 30 days and the follower count; once a week refresh the token.

## Console (`landing/admin/js/views/instagram.js`, nav "Instagram")
Account card (username, followers, posts left today of 50, token age) or a connect form. Tabs:
drafts (draft / approved / failed), scheduled (scheduled / publishing), published. A post opens in
an editor: Instagram-style preview with swipe, caption with character / hashtag counters and rule
warnings, actions by status. Published: stats, permalink, comments with reply / hide. "New post":
upload images or video (PNG/WebP → JPEG in the browser), type inferred, story optional.

## Claude's drafts
`tools/instagram/push.mjs <id>…` uploads `posts/<id>/out/*.jpg` and creates the draft in
Firestore (source "claude"); post.json keeps the console id so a re-push updates the same draft.

## Not included
No `ff_*` flag and no legal-doc change: admin-only tool, nothing in the app, no user data sent.

## Testing
`functions/adminInstagram.test.js` for validation, state transitions, the claim, Graph request
building and the runner (Graph mocked through `fetchImpl`). One live probe after Koby connects.
Deploy: functions, firestore + storage rules, hosting.
