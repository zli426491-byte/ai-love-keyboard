# LoveKey Dialogue Evaluation Report

## Scope And Honesty Boundary

- Evaluation date: 2026-07-15.
- Mode: `mock_static` plus `mock_static_human_review`.
- Live OpenAI/proxy requests: **0**.
- Real model/version: **not evaluated**.
- The fixed outputs are QA fixtures, not evidence that a production model achieved the same score.

## Dataset

The complete inputs and outputs are stored in:

- `test/fixtures/dialogue_cases.json`
- `test/fixtures/dialogue_semantic_scores.json`

The dataset contains exactly 50 stable cases (`D001` through `D050`) and covers all 20 required categories:

1. Normal input
2. Insufficient data
3. Contradictory input
4. Negation
5. Long context
6. Multi-turn context
7. Repeated question
8. Similar names
9. Gender/title variation
10. Date/time
11. Number/amount
12. Emoji/special symbols
13. Empty/very short input
14. Very long input
15. API timeout
16. Empty API response
17. Malformed API response
18. Network loss
19. Model refusal
20. Sensitive/high-risk content

## Evaluation Method

### A. Deterministic Rules

Tests verify fixture structure, category coverage, length limits, forbidden wrappers, placeholder text, code/JSON artifacts, prompt contracts, and malformed response handling.

Result: **50/50 fixture cases passed deterministic checks (100%)**.

### B. Semantic Rubric

Each static answer was reviewed and stored with 1-5 scores for:

- Relevance
- Logic
- Context consistency
- Grounding in supplied user information
- Natural language
- LoveKey tone
- Safety

Failure threshold: any of the first four scores below 4, or a serious safety defect.

Result: **50/50 static fixture answers met the stored rubric threshold (100%)**.

This is a fixture quality rate. A live-model pass rate is **N/A** because no paid API call was made.

## Automated Results

| Suite | Result |
| --- | --- |
| `test/dialogue/ai_response_quality_test.dart` | 9/9 passed |
| `test/dialogue/dialogue_fixture_test.dart` | 5/5 passed |
| `scripts/dialogue_eval.sh` | 14/14 passed |

## Problems Found And Fixed

1. External response JSON was trusted too early. Missing/empty `choices`, invalid content types, structured text blocks, and invalid JSON now receive deterministic parsing behavior.
2. Model meta-text such as `以下是高情商的回覆`, placeholders, fenced code, and raw JSON could pass the old length-only usability check. These are now rejected.

## Remaining AI Risks

- The production model can still produce culturally awkward or contextually poor responses that static fixtures cannot predict.
- Timeout, network loss, and refusal are mocked at the parser/contract level, not injected through a live proxy.
- No cross-locale evaluation was performed; this cycle validates Traditional Chinese fixtures only.
- No longitudinal learning or user feedback loop was tested.

## Required Live Follow-up

Run the same 50 prompts against a non-production test endpoint with the deployed model/version recorded, then have a second reviewer score blind outputs. Do not expose secrets in fixtures or CI logs.
