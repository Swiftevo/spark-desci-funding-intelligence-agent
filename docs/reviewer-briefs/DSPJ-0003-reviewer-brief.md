# Spark DeSci Reviewer Brief

**Project**: LLM Evaluators in PGF
**Project ID**: DSPJ-0003
**Participation ID**: DSPT-00003
**Mode**: agent-glm-5.1
**Review Status**: needs_more_evidence

## Executive Summary

This project proposes building an LLM-based evaluation methodology for public goods funding (PGF) proposals, aiming to reduce evaluation costs so more funds flow directly to impact projects. The team has completed research design—selecting five LLM models, defining RBTS vs. averaging test protocols, mapping token costs, and identifying five past funding rounds for study. However, the project is at a very early stage (research design only), with no prototype, pilot results, or published work yet. The core claim that LLMs can reliably replace or augment human evaluators in high-stakes funding decisions carries significant methodological and ethical risks that are not substantively addressed in the proposal.

## Extracted Claims

- LLMs can evaluate funding applications and help decide who should receive public goods funding
- Using LLM evaluators will reduce the cost of funding rounds
- Cost reduction will result in more money going directly to climate, community, and social impact projects
- The team has 20+ years of combined IT experience, AI engineering expertise, and blockchain/PGF experience
- Five LLM models have been selected for comparative testing
- RBTS vs. averaging tests have been defined as the evaluation methodology
- Five past funding rounds have been identified for retrospective study

## Milestone Assessment

- Research design completed — this is the only confirmed milestone and represents early-stage planning with no experimental results
- Model selection (5 LLMs) — claimed but no evidence of which models or selection criteria
- Test protocol definition (RBTS vs. averaging) — claimed but no documentation or pre-registration provided
- Token cost mapping — claimed but no data shared
- Past round identification (5 rounds) — claimed but rounds not specified
- No prototype, pilot study, or preliminary results exist at this stage

## Evidence Found

- Project self-reports research design completion including model selection, test protocol, and round identification
- Team claims relevant domain expertise (AI + PGF experience)
- The project type is classified as 'Research,' consistent with its early-stage nature
- Cross-project comparison shows DSPJ-0003 is the only project in this round directly addressing AI-based funding evaluation, indicating niche positioning

## Missing Evidence

- No published papers, preprints, or prior work from the team on LLM evaluation or PGF
- No prototype, demo, or pilot results demonstrating feasibility
- No documentation of the research design (e.g., methodology paper, pre-registration)
- No specification of which 5 LLM models were selected or why
- No identification of which 5 past funding rounds will be studied
- No discussion of ground truth: how will LLM outputs be validated against human evaluator decisions?
- No analysis of known LLM biases (demographic, linguistic, topical) and how they will be mitigated in a funding context
- No ethical framework for replacing/augmenting human judgment in resource allocation decisions
- No GitHub repository or open-source artifacts
- No budget breakdown or token cost estimates shared despite claiming to have mapped them

## Academic Context

> **Archived note**: This brief was generated before Semantic Scholar integration. Academic context in this archived artifact used the earlier placeholder adapter and should not be treated as verified literature support. New agent runs use Semantic Scholar metadata when available.

- Field maturity: emerging_to_active — LLM-based evaluation is a hot topic but rigorous empirical validation in funding contexts is scarce
- Key credibility questions remain: (1) What peer-reviewed or preprint literature supports the central claim? (2) Is the proposed method novel, or mainly an application of known methods? (3) Are there known limitations, benchmark issues, or reproducibility concerns?
- Known concerns in the literature include LLM evaluation bias, hallucination, positional bias in ranking tasks, and lack of calibration — none of which are addressed in the proposal

## Cross-Project Comparison

DSPJ-0003 is the only project in this cohort directly targeting AI-based funding evaluation, giving it a unique niche. DSPJ-0002 (Narrative Audits for Public-Goods) is complementary — it stress-tests project narratives, which could be an input signal for an LLM evaluator, but operates in a different domain (Social/Community vs. AI/Data) and has more demonstrated progress (delivered audits, hackathon wins). DSPJ-0049 (FunDeSci) and DSPJ-0027 (Spark DeSci) are funding infrastructure projects but do not use AI for evaluation. Compared to these peers, DSPJ-0003 has the least demonstrated progress (research design only) and the highest technical risk, as it depends on unproven LLM capabilities in a high-stakes domain.

## Funding Memory Observations

- This is a research project with no prior funding history or deliverables visible in this round
- The project's value proposition (cost reduction) is compelling if proven, but currently unsubstantiated
- The team plans to consult human funding round evaluators — this is a positive signal but has not yet been executed
- No evidence of iterative development or community feedback incorporation

## Risk Flags

- [high] LLM evaluation bias in funding decisions: LLMs are known to exhibit demographic, linguistic, and topical biases. In a funding context, biased evaluations could systematically disadvantage certain communities or project types. The proposal does not address bias mitigation.
- [high] Unvalidated core hypothesis: The central claim that LLMs can reliably evaluate funding proposals has no empirical support in this proposal. No pilot data, benchmarks, or prior publications are provided.
- [medium] Early stage with no deliverables: The project is at 'research design completed' stage with no prototype, pilot results, or published methodology. Funding a research design without evidence of execution capability carries execution risk.
- [high] Ethical implications of AI replacing human evaluators: Replacing human judgment with AI in resource allocation raises serious ethical concerns about accountability, transparency, and fairness. The proposal does not discuss these implications or propose safeguards.
- [medium] Lack of ground truth validation methodology: The proposal mentions RBTS vs. averaging tests but does not explain how LLM outputs will be validated against human evaluator decisions or what constitutes acceptable agreement.
- [low] Opaque team credentials: Team claims 20+ years IT experience and AI/PGF expertise but no specific credentials, publications, or prior project links are provided for verification.

## Suggested Reviewer Questions

- Can you provide documentation of your research design, including model selection criteria, test protocols, and the specific past funding rounds you plan to study?
- How will you establish ground truth for evaluating whether LLM outputs align with high-quality human evaluation? What agreement threshold would you consider successful?
- What specific biases (demographic, linguistic, topical) have you identified as risks in LLM-based funding evaluation, and how do you plan to measure and mitigate them?
- What ethical framework or safeguards do you propose for deploying AI in high-stakes funding decisions, particularly regarding accountability and transparency?
- Can you share any preliminary results, even from small-scale pilot tests, that demonstrate LLMs can produce evaluations comparable to human evaluators?
- What is your contingency plan if LLM evaluations show poor agreement with human evaluators or exhibit systematic bias?
- How will this research be made reproducible? Will you pre-register your methodology and share data/code openly?
- What is the specific budget breakdown, and how does the mapped token cost inform the feasibility of your approach at scale?
- Have you engaged with any human funding round evaluators yet, and what insights have they provided about their evaluation criteria?
- How does your approach differ from simply using LLMs as a screening tool (low-stakes) versus a decision-making tool (high-stakes), and which use case are you targeting?

## Human Review Support Status

**needs_more_evidence**
