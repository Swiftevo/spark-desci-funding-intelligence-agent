# Spark DeSci Reviewer Brief

**Project**: OneHealth
**Project ID**: DSPJ-0038
**Participation ID**: DSPT-00038
**Mode**: agent-glm-5.1
**Review Status**: needs_more_evidence

## Executive Summary

OneHealth proposes a health identity system allowing patients to carry their medical history. The project is at the 'design ready' stage with no implementation, prototype, or pilot evidence presented. The proposal is extremely thin—lacking technical architecture, standards references (e.g., HL7 FHIR, W3C DID), interoperability strategy, or any concrete artifact. The domain of portable/decentralized health records is an active research area with significant prior work (PHRs, blockchain-based health identity, national e-health systems), making novelty claims difficult to assess without more specificity. Compared to peer projects in this round, OneHealth shows the least demonstrable progress.

## Extracted Claims

- [VERIFIABLE] System design has been completed (stated as 'Design ready')
- [ASPIRATIONAL] Health identity system allowing patients to carry medical history
- [ASPIRATIONAL] Improves healthcare efficiency and saves lives
- [ASPIRATIONAL] Preparing pilots (no evidence of pilot partners, locations, or timelines provided)
- [ASPIRATIONAL] Focus on real-world infrastructure and healthcare systems

## Milestone Assessment

- No formal milestones are defined in the proposal. The only stated progress is 'System design completed and preparing pilots,' but no design document, architecture diagram, specification, or whitepaper is referenced or linked.
- No evidence of pilot preparation: no pilot partners, healthcare institutions, regulatory engagement, or timelines are mentioned.
- No GitHub repository, demo, or technical artifact is available for inspection.

## Evidence Found

- Project exists on Artizen fund platform with a basic profile page
- Self-reported progress status: 'Design ready'
- Project categorized under Biotech/Health domain with Data Storage and Identity functions

## Missing Evidence

- No system design document, architecture diagram, or technical specification
- No prototype, demo, or working code (no GitHub or repository linked)
- No evidence of pilot partnerships or institutional engagement
- No reference to healthcare data standards (HL7 FHIR, OpenEHR, W3C DID, etc.)
- No regulatory or compliance considerations (HIPAA, GDPR, data sovereignty)
- No user research, needs validation, or stakeholder interviews
- No comparison with existing solutions (Epic MyChart, Apple Health Records, national e-health IDs, etc.)
- No security or privacy architecture for sensitive health data

## Academic Context

> **Note**: Academic context is currently based on a placeholder adapter and GLM-5.1 general knowledge, not verified literature retrieval. See DEMO_REMARKS.md for details.

- The domain of decentralized/portable health records is an active research area with substantial prior work. Personal Health Records (PHRs) have been studied for over two decades. Blockchain-based health identity and self-sovereign identity (SSI) for healthcare are emerging-to-active research fields.
- Key prior work includes: national e-health ID systems (Estonia's e-Health, India's Ayushman Bharat), W3C Decentralized Identifiers (DIDs) applied to healthcare, HL7 FHIR-based patient data portability standards, and commercial solutions like Apple Health Records and Epic MyChart.
- Credibility questions remain: (1) What peer-reviewed literature supports this specific approach? (2) Is the proposed method novel, or mainly an application of known methods? (3) Are there known limitations—interoperability challenges, adoption barriers, data quality issues—in this research area that the project addresses?

## Cross-Project Comparison

Compared to peer Biotech/Health projects in this round: (1) INFLAMM AI (DSPJ-0011) is also a Product-type health project but has progressed to 'Website + waitlist' stage, showing more tangible progress than OneHealth's 'Design ready.' (2) Asterisk Women Health (DSPJ-0045) focuses on women's health data and has achieved 'Viral + grants' traction, demonstrating real-world engagement. OneHealth is the least mature of the three, with no external validation, no community, and no artifact beyond a claimed design. There is no direct functional overlap—INFLAMM AI is an AI agent, Asterisk is media/narrative—but all three touch health data, suggesting the round has multiple health-data projects at varying maturity levels.

## Funding Memory Observations

- OneHealth aligns with the DeSci round's Biotech/Health domain and touches on decentralized identity and data storage—both relevant to DeSci infrastructure goals.
- However, the proposal is among the thinnest in the round, providing almost no detail for reviewers to evaluate technical merit or feasibility.
- The 'Product' project type implies expectation of a deliverable, but no product artifact exists yet—only a claimed design phase.
- No evidence of prior funding, community building, or institutional partnerships that would de-risk the project.

## Risk Flags

- [high] Extremely thin proposal with no technical detail: The raw text contains only 4 short sentences across all sections. No architecture, standards, technology stack, or design document is referenced. Reviewers cannot assess technical feasibility.
- [high] Aspirational impact claims without evidence: Claim 'Improves healthcare efficiency and saves lives' is aspirational with no supporting evidence, user research, or validation of any kind.
- [medium] Significant prior work in this domain not acknowledged: Portable health records and health identity systems have extensive prior work (national e-health IDs, PHRs, FHIR standards, Apple Health Records, blockchain health identity research). The proposal does not acknowledge or differentiate from any of these.
- [high] No regulatory or privacy considerations for sensitive health data: A health identity system handling medical history must address HIPAA, GDPR, data sovereignty, and consent management. None are mentioned.
- [medium] Unverifiable pilot preparation claim: The claim 'preparing pilots' cannot be verified—no pilot partners, institutions, locations, or timelines are provided.

## Suggested Reviewer Questions

- Can you share the system design document or architecture diagram that you describe as 'completed'?
- What specific healthcare data standards (HL7 FHIR, OpenEHR, W3C DID, etc.) does your system build on or interoperate with?
- How does OneHealth differ from existing portable health record solutions such as Apple Health Records, Epic MyChart, or national e-health ID systems (e.g., Estonia, India)?
- What is your approach to data privacy, consent management, and regulatory compliance (HIPAA, GDPR)?
- Who are your pilot partners, and what is the timeline for pilot deployment?
- What is the technical architecture—centralized, federated, or fully decentralized? What blockchain or distributed ledger, if any, is being used?
- Have you conducted any user research or needs validation with patients or healthcare providers?
- What is your plan for data interoperability with existing Electronic Health Record (EHR) systems?

## Human Review Support Status

**needs_more_evidence**
