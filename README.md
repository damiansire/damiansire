# GitHub Account Cleanup Plan

This account is officially in cleanup mode as of Saturday, April 11, 2026. After several years of building public and private repositories, I am starting a deep dive to organize this collection.

## Action Plan

I am building an AI-powered repository classifier to identify what I have and how to handle it. To test my limits, I am following a specific technical workflow:

* **Build an ETL:** Create a pipeline to classify every repository in this account.
* **Evaluation:** Determine which projects stay active.
* **Restructure:** Group, archive, or reorganize the codebase based on those results.

## Cleanup Status - Storage Optimization

**Status April 12:** Experimenting with optimal storage strategies

Currently evaluating the best approach for storing repository metadata and classification data:

### Database vs JSON Storage Analysis
- **Field Size Considerations:** Analyzing optimal storage format based on field dimensions
- **Information Volume:** Testing scalability with varying data quantities
- **Link Quantity:** Evaluating performance impact of storing cross-repository references

**Experimentation:** [json-portable-db](https://github.com/damiansire/json-portable-db)

This phase focuses on determining the ideal balance between:
- Database structure efficiency
- JSON file portability and accessibility
- Performance under different data scales
