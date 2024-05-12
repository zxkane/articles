---
title: "Scan Your Code with Ephemeral SonarQube in GitHub Actions"
description : "Streamline code quality inspection with ephemeral SonarQube in GitHub Actions workflows"
date: 2024-05-12
lastmod: 2024-05-12
draft: false
thumbnail: ./cover.png
usePageBundles: true
codeMaxLines: 50
codeLineNumbers: true
categories:
- blogging
isCJKLanguage: false
tags:
- Clean Code
- SonarQube
- Github Actions
- CI
- DevOps
---

As developers, we all know the importance of maintaining high code quality standards. One powerful tool that can help us achieve this is [SonarQube][sonarqube], a renowned platform for continuous code quality inspection. However, setting up and maintaining a dedicated SonarQube instance can be a cumbersome task, requiring significant resources and ongoing maintenance.

Fortunately, GitHub Actions offers a convenient solution by allowing us to spin up an ephemeral (short-lived) SonarQube instance directly within our workflow. This approach streamlines the process, eliminating the need for a permanent SonarQube server while still reaping the benefits of its code analysis capabilities.

## Why Ephemeral SonarQube?

Using an ephemeral SonarQube instance in your GitHub Actions workflow provides several advantages:

1. **No Infrastructure Overhead**: With ephemeral SonarQube, you don't need to worry about provisioning and maintaining a dedicated server or virtual machine for SonarQube. This reduces infrastructure costs and management overhead.
1. **Scalability**: Ephemeral instances can be easily spun up and torn down as needed, making the process highly scalable and adaptable to your project's requirements.
1. **Consistent Environment**: By running SonarQube within the GitHub Actions environment, you ensure a consistent and reproducible analysis environment across all your builds. For open-source projects, it validates every Pull Request without requiring a SonarQube instance and permissions for contributors.
1. **Secure and Isolated**: Each ephemeral SonarQube instance is isolated and secure, reducing the risk of cross-contamination or security vulnerabilities.

## Setting up Ephemeral SonarQube in GitHub Actions

Setting up an ephemeral SonarQube instance in your GitHub Actions workflow is a straightforward process. Here's a high-level overview of the steps involved:

1. **Define a GitHub Actions Workflow**: Create a new workflow file (e.g., .github/workflows/sonar-check.yml) in your repository.
1. **Configure SonarQube Instance as a service**: Run SonarQube instance as a [service container][service-containers]. Specify the instance details, including the version and edition (community or enterprise) you want to use. Then, configure the custom quality profiles and quality gate for meeting the code quality standards of your project.
1. **Build Your Project and Run Tests with Reports**: Build your code and run tests for coverage reports, if applicable.
1. **Trigger Code Analysis**: Use the [sonarsource/sonarqube-scanner-action][sonarqube-scanner-action] or another community action using SonarQube Scanner CLI to run the SonarQube Scanner against your codebase, configuring any necessary analysis properties or exclusions.
1. **Check the Analysis Result**: After the analysis is complete, check if the result meets the quality gate or not.
1. **Update Analysis Result to Pull Request**: Write the SonarQube analysis result to the Pull Request as a new comment. It would be ideal to comment on the new code for any new finding issues.

Here's an example of how your GitHub Actions workflow might look:

```yaml
name: code scans
on:
  pull_request: {}
  workflow_dispatch: {}
jobs:
  sonarqube:
    name: sonarqube scan
    runs-on: 'ubuntu-latest'
    services:
      sonarqube:
        image: public.ecr.aws/docker/library/sonarqube:10-community
        ports:
          - 9000:9000
    steps:
      - uses: actions/checkout@v4
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: 20.x
      - name: Install dependencies
        run: yarn install --check-files && yarn --cwd example/ install --check-files
      - name: Run build and unit tests
        run: npx projen compile && npx projen test
      - name: Configure sonarqube
        env:
          SONARQUBE_URL: http://localhost:9000
          SONARQUBE_ADMIN_PASSWORD: ${{ secrets.SONARQUBE_ADMIN_PASSWORD }}
        run: |
          bash .github/workflows/sonarqube/sonar-configure.sh
      - name: SonarQube Scan
        uses: sonarsource/sonarqube-scan-action@master
        env:
          SONAR_HOST_URL: http://sonarqube:9000
          SONAR_TOKEN: ${{ env.SONARQUBE_TOKEN }}
        with:
          args: >
            -Dsonar.projectKey=pr-${{ github.event.pull_request.number }}
      # Check the Quality Gate status.
      - name: SonarQube Quality Gate check
        id: sonarqube-quality-gate-check
        uses: sonarsource/sonarqube-quality-gate-action@master
        # Force to fail step after specific time.
        timeout-minutes: 5
        env:
          SONAR_TOKEN: ${{ env.SONARQUBE_TOKEN }}
          SONAR_HOST_URL: http://localhost:9000
      - uses: phwt/sonarqube-quality-gate-action@v1
        id: quality-gate-check
        if: always()
        with:
          sonar-project-key: pr-${{ github.event.pull_request.number }}
          sonar-host-url: http://sonarqube:9000
          sonar-token: ${{ env.SONARQUBE_TOKEN }}
          github-token: ${{ secrets.PROJEN_GITHUB_TOKEN }}
      - name: Comment results and findings on Pull Request
        uses: zxkane/sonar-quality-gate@master
        if: always()
        env:
          DEBUG: true
          GITHUB_TOKEN: ${{ secrets.PROJEN_GITHUB_TOKEN }}
          GIT_URL: "https://api.github.com"
          GIT_TOKEN: ${{ secrets.PROJEN_GITHUB_TOKEN }} 
          SONAR_URL: http://sonarqube:9000
          SONAR_TOKEN: ${{ env.SONARQUBE_TOKEN }}
          SONAR_PROJECT_KEY: pr-${{ github.event.pull_request.number }}
        with:
          login: ${{ env.SONARQUBE_TOKEN }}
          skipScanner: true
```

In this example, the workflow is triggered on pull request events to the main branch. The `sonarsource/sonarqube-scanner-action` is used to install the SonarQube Scanner and perform the code analysis. The SONAR_TOKEN environment variables is used to authenticate with the ephemeral SonarQube instance and its URL is specified as `localhost:9000` or `sonarqube:9000` which only could be accessed from the workflow runtime, respectively.

After the analysis is complete, the `sonarsource/sonarqube-quality-gate-action` is used to check if the code meets the defined quality gate criteria. The customize quality gate is configured in the **Configure sonarqube** step.

The final step comments the results on the Pull Request and adds finding issues as inline comments too.

You can check the complete sample in [this repo][snat].

## Conclusion

Incorporating ephemeral SonarQube into your GitHub Actions workflow streamlines the process of continuous code quality inspection. By leveraging the power of SonarQube without the overhead of maintaining a dedicated instance, you can ensure that your codebase adheres to high quality standards with minimal effort.

Give ephemeral SonarQube a try in your next project and experience the benefits of seamless code analysis and quality assurance within your GitHub Actions workflows.

[sonarqube]: https://www.sonarsource.com/products/sonarqube/
[service-containers]: https://docs.github.com/en/actions/using-containerized-services/about-service-containers
[sonarqube-scanner-action]: https://github.com/marketplace/actions/official-sonarqube-scan
[snat]: https://github.com/zxkane/snat