# Instructions for Managing Your New dbt Project

This document provides a step-by-step guide to managing your newly created dbt project within the Data Modeling VS Code environment. This guide assumes that data replication has been completed through the Data Replication module and a new project has been initialized.

## Introduction
Project Example: NASA Sky News
https://api.nasa.gov/ - APOD Data.

## Prerequisites

Before starting data modeling, ensure that:
1. Data replication is complete through the Data Replication module
2. A new dbt project has been initialized
3. You have access to the Data Modeling VS Code environment

## 1. Checkout Your Project Branch

1. Open the Data Modeling VS Code environment
2. Click on the repository management icon (usually located in the bottom left corner)
3. Select "Checkout To..."
4. In the configuration window, choose the branch generated during the dbt project initialization. This branch will contain your new project

## 2. Open Your Project Folder in VS Code

1. In VS Code, click the three horizontal lines (the "hamburger" menu) in the top left corner
2. Choose "File" -> "Open Folder"
3. In the "Open Folder" configuration window, select your project folder
4. Click the "OK" button. VS Code will now be focused on your project directory

## 3. Verify Profile Configuration

Upon opening your project directory, profile files for dbt Power User and Lightdash will be automatically created:

* `.dbt/profiles.yml`: Configuration for dbt and dbt Power User
* `.lightdash/profiles.yml`: Configuration for the Lightdash data exploration tool

These profiles are pre-configured for development. Verify their contents to ensure they align with your development environment.

## 4. Choose Your Development Approach

You have two options for developing your dbt project:

### Option A: Using dbt Power User Extension (Recommended)

dbt Power User provides a rich integrated development environment within VS Code with features like:
- Visual lineage graph (upstream/downstream model dependencies)
- One-click model compilation and building directly from the editor
- Automatic documentation generation with AI assistance
- Integrated testing, column-level lineage, and query previews

#### Setup dbt Power User:
1. Open the dbt Power User panel (dbt icon in the Activity Bar on the left)
2. The extension reads `.dbt/profiles.yml` automatically — no additional setup needed
3. If prompted, confirm the dbt project path points to your `dbt_project.yml`
4. Environment variables (including `GIT_BRANCH`) are pre-configured in workspace settings

#### Using Claude Code AI Assistant:
Claude Code is pre-installed and can accelerate your dbt development:
- Press `Ctrl+Shift+P` → "Claude: Open" to open the Claude Code panel
- Ask Claude to generate dbt models, write tests, or review your SQL
- Use it to auto-generate `.yml` documentation for your models

### Option B: Using Lightdash CLI (Manual Approach)

Lightdash CLI provides command-line tools for dbt development with features like:
- Command-line model compilation and building
- Manual documentation management
- Custom testing and validation

#### Setup Lightdash:
1. Set up environment variables in your terminal for your data warehouse:

   Example: Snowflake
   ```bash
   # Authentication config
   user: "{{ env_var('SNOWSQL_USERNAME') }}"
   password: "{{ env_var('SNOWSQL_PASSWORD') }}"
   role: "{{ env_var('SNOWSQL_ROLE') }}"
   ```

   Example: BigQuery
   ```bash
   # Authentication config
   gcloud auth login
   gcloud auth application-default login
   ```

## 5. Clean Up Initial dbt Project Files

1. **Edit `dbt_project.yml`**: Remove the line under the `models:` key referencing the default dbt-core initiated examples. This line typically looks like `models: <your_project>`. Use the VS Code file explorer to find the file, then edit the contents and save.
2. **Remove Example Models**: Delete the `example` folder located within the `models` directory. Use the VS Code file explorer to delete the entire folder.

## 6. Create Your Data Mart

1. Create a new folder named `marts` at the root of your dbt project
2. Inside the `marts` folder, create two new files:
   * `model_a.sql`: This file will contain your SQL transformation logic
   * `model_a.yaml`: This file will contain the schema definition and tests for your model

## 7. Write Your Model Code

Edit `marts/model_a.sql` to implement your data transformation logic. Example:
```sql
-- marts/model_a.sql
-- {{ insert your SQL code here }}
-- For example:
-- SELECT
--     column_a,
--     column_b
-- FROM
--     {{ source('your_source', 'your_table') }}
```

# Example: `nasa_sky_news.sql`: NASA Mart file for APOD data
```sql
-- marts/nasa_sky_news.sql
{{
  config(
    materialized='incremental',
    unique_key='id',
    incremental_strategy='merge',
    on_schema_change='sync_all_columns',
    re_data_time_filter="date"
  )
}}

WITH final AS (
SELECT
    date,
    url,
    hdurl,
    title,
    explanation,
    media_type
FROM {{ ref('stg_nasa_apod') }}
)

SELECT
  {{ dbt_utils.generate_surrogate_key(['date', 'url']) }} AS id,
  date,
  url,
  hdurl,
  title,
  explanation,
  media_type,
  CASE
      WHEN media_type = 'image' AND URL IS NOT NULL THEN
          CONCAT('<a href="', COALESCE(hdurl, URL, '#'), '" target="_blank"><img src="', URL, '" width="200" height="150" style="object-fit: cover; cursor: pointer; border: 2px solid #28a745; transition: transform 0.2s;" alt="🖼️ ', TITLE, '" title="Click to view HD image" onmouseover="this.style.transform=\'scale(1.05)\'" onmouseout="this.style.transform=\'scale(1)\'"></a>')
      WHEN media_type = 'video' THEN
          CONCAT('<a href="', COALESCE(URL, '#'), '" target="_blank"><img src="https://www.iconpacks.net/icons/1/free-video-icon-836-thumb.png" width="200" height="150" style="object-fit: cover; cursor: pointer; border: 2px solid #007bff;" alt="🎥 Video: ', TITLE, '" title="Click to watch video"></a>')
      ELSE
          CONCAT('<img src="https://images.vexels.com/media/users/3/153524/isolated/preview/98eb14077d749c76030a96a08679e792-barcode-stroke-icon.png?w=360" width="200" height="150" style="object-fit: cover; opacity: 0.7;" alt="📄 Other: ', TITLE, '">')
  END AS image_html
FROM final
```
### 7.1 If using the custom packages' functions, do not forget to add them to the packages.yml file
# Example:
```yaml
packages:
  - package: dbt-labs/dbt_utils
    version: [">=1.0.0", "<1.2.0"]
```

## 8. Compile and Build Your Model

### If Using dbt Power User:
1. Open your model file (e.g., `nasa_sky_news.sql`) in the VS Code editor
2. Click the **▶ Run** or **⚡ Build** button that appears above the SQL file in the dbt Power User toolbar
3. Alternatively, right-click the file in the dbt Power User sidebar and choose "Run model"
4. Compilation results and query previews appear in the dbt Power User panel

### If Using Lightdash CLI:
Run one of the following commands in your terminal:
```bash
dbt compile --exclude package:re_data --profiles-dir .lightdash/
or
lightdash compile --exclude package:re_data --profiles-dir .lightdash/
```

## 9. Generate Documentation

### If Using dbt Power User:
1. Open the dbt Power User panel and navigate to the **Documentation** section
2. Click **Generate Docs** to auto-generate YAML documentation for your models
3. Use the AI-assisted documentation feature to auto-fill column descriptions
4. Review the automatically generated descriptions for accuracy
5. Save the documentation — dbt Power User writes directly to your `.yml` files

### If Using Lightdash CLI:
1. Run the following commands to generate documentation structure:
   ```bash
   lightdash generate --exclude package:re_data --profiles-dir .lightdash/
   ```
2. Edit the generated YAML files in your models directory
3. Add descriptions, tests, and other metadata as needed
4. Validate your documentation:
   ```bash
   lightdash validate --exclude package:re_data --profiles-dir .lightdash/
   ```

## After Models YAML generation, don't forget to add the following documentation and tests:
# Example:
```yaml
  - name: nasa_sky_news
    description: "This model contains NASA's Astronomy Picture of the Day (APOD) data."
    columns:
      - name: id
        description: "Unique identifier for each APOD entry."
        data_tests:
          - not_null
          - unique
        meta:
          dimension:
            type: string
```

## 10. Code Quality Checks

Before committing your changes, run the following linting tools to ensure code quality:

1. YAML Linting:
   ```bash
   yamllint -c yamllint-config.yaml -f colored --no-warnings models/
   ```
   This will check your YAML files for proper formatting and structure.

2. SQL Linting:
   ```bash
   sqlfluff lint --annotation-level failure -p 10 .
   ```
   This will check your SQL files for proper formatting and best practices.

Fix any issues reported by these tools before proceeding to commit your changes.

## 11. Commit and Push Changes

If all steps are successful:
1. Commit your changes to your local repository
2. Push them to the remote repository
3. This will update the project on your remote branch

## Additional Resources

- For more information about dbt project structure and best practices, refer to the [dbt documentation](https://docs.getdbt.com/)
- For dbt Power User extension features and configuration, see the [dbt Power User documentation](https://docs.myaltimate.com/)
- For Claude Code AI assistant usage, visit the [Claude Code documentation](https://docs.anthropic.com/en/docs/claude-code)
- For Lightdash CLI usage and configuration, visit the [Lightdash documentation](https://docs.lightdash.com/)
- For YAML linting rules, see the [yamllint documentation](https://yamllint.readthedocs.io/)
- For SQL linting rules, see the [SQLFluff documentation](https://docs.sqlfluff.com/)
