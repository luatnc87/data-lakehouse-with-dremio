# Build a Data Lakehouse With Dremio, DBT and Power BI

In the realm of modern data architecture, the amalgamation of a Data Lakehouse framework proves transformative for organizations seeking agile data management and potent analytics. Enter Dremio, a versatile data lakehouse platform that sets the stage for unified data integration and acceleration.

This blog post embarks on an exploration of how Dremio, coupled with the dynamic capabilities of DBT for transformation and Power BI for visualization, crafts a robust and complete Lakehouse solution. Dremio, acting as the foundational layer, bridges the gap between data lakes and warehouses, offering a unified environment for data storage, processing, and acceleration.

DBT steps in as the transformation powerhouse, enabling structured data modeling and preparation within the Dremio Lakehouse ecosystem. Its SQL-based, version-controlled workflows streamline the transformation layer, ensuring clean and reliable data for downstream analysis.

Complementing this transformative journey, Power BI emerges as the orchestrator of visual narratives, leveraging Dremio's optimized data for crafting compelling dashboards and reports. Its user-friendly interface and rich visualization capabilities transform data insights into actionable information, driving informed decision-making.

![architecture_diagram.png](images%2Farchitecture_diagram.png)


# Components Introduction
## Dremio
In the fast-paced world of data management and analytics, Dremio has emerged as a game-changer, offering a powerful platform designed to streamline data access, acceleration, and collaboration across organizations. At the heart of Dremio's innovative approach lies its commitment to simplifying complex data architectures, providing self-service access to data, and accelerating data-driven decision-making processes.

### Dremio: Redefining Data Access and Analytics
Dremio is a comprehensive data lakehouse platform that acts as a unifying force in modern data architectures. It seamlessly bridges the gap between data lakes and warehouses, enabling users to effortlessly access, analyze, and derive insights from diverse and distributed datasets.

**Key Features of Dremio Include**:
- **Data Virtualization**: Dremio’s data virtualization capabilities allow users to access and query data from various sources without the need for data movement or replication, ensuring real-time access to updated information.
- **Data Catalog and Curation**: The platform provides a centralized data catalog, making it easier to discover, understand, and collaborate on datasets, ensuring data governance and reliability.
- **Acceleration and Performance**: Dremio employs an advanced acceleration engine that optimizes query performance by leveraging techniques like columnar caching and reflection, enabling faster analytics even on massive datasets.
- **Self-Service Analytics**: Its user-friendly interface empowers non-technical users to perform ad-hoc queries, data preparation, and visualization, democratizing data access across the organization.

### Dremio OSS
Dremio Open Source Software (Dremio OSS) embodies the core principles of Dremio in an open-source offering, empowering users with foundational capabilities to build, test, and deploy their data solutions.

> **NOTE**: *Dremio OSS will be used in this tutorial.*

### Iceberg & Parquet
Iceberg is a table format designed for managing data lakes, offering several key features to ensure data quality and scalability:
- **Schema Evoluation**: One of Iceberg's standout features is its support for schema evolution. You can add, delete, or modify columns in your datasets without breaking existing queries or data integrity. This makes it suitable for rapidly evolving data lakes.
- **ACID Transformations**: Iceberg provides ACID (Atomicity, Consistency, Isolation, Durability) transactions, ensuring data consistency and reliability in multi-user and multi-write environments.
- **Time-Travel Capabilities**: Iceberg allows you to query historical versions of your data, making it possible to recover from data errors or analyze changes over time.
- **Optimized File Storage**: Iceberg optimizes file storage by using techniques like metadata management, partitioning, and file pruning. This results in efficient data storage and retrieval.
- **Connectivity**: Iceberg supports various storage connectors, including Apache Hadoop HDFS, Amazon S3, and Azure Data Lake Storage, making it versatile and compatible with different data lake platforms.

Parquet is a columnar storage format that optimizes data for query and analysis. It organizes data into columns, enabling efficient compression and retrieval of specific columns, reducing I/O and enhancing query performance. Parquet's compatibility with various big data processing frameworks and its ability to handle nested and complex data structures make it a popular choice for storing and processing large datasets efficiently.

Both Apache Iceberg and Parquet File play crucial roles in modern data ecosystems, offering optimized storage and efficient querying capabilities that empower data-driven organizations to manage and analyze vast amounts of data effectively.

## DBT
dbt, which stands for Data Build Tool, is a command-line tool that revolutionizes the way data transformations and modeling are done. Here's a deeper dive into dbt's capabilities:
- **Modular Data Transformations**: dbt uses SQL and YAML files to define data transformations and models. This modular approach allows you to break down complex transformations into smaller, more manageable pieces, enhancing mantainability and version control.
- **Data Testing**: dbt facilitates data testing by allowing you to define expectations about your data. It helps ensure data quality by automatically running tests against your transformed data.
- **Version Control**: dbt projects can be version controlled with tools like Git, enabling collaboration among data professionals while keeping a history of changes.
- **Incremental Builds**: dbt supports incremental builds, meaning it only processes data that has changed since the last run. This feature saves time and resources when working with large datasets.
- **Orchestration**: While dbt focuses on data transformations and modeling, it can be integrated with orchestration tools like Apache Airflow or dbt Cloud to create automated data pipelines.

## Microsoft Power BI
Power BI stands as a formidable force in the realm of business intelligence and analytics, offering a suite of tools that revolutionize the way organizations visualize, analyze, and derive insights from their data. As a robust and user-friendly platform developed by Microsoft, Power BI empowers users at all levels to harness the power of data, transforming it into actionable insights that drive informed decision-making.

# Setting up Dremio, DBT, Power BI Desktop
## Setting up Dremio OSS
### Preparing the Docker file and setting up the Dremio services
We will install `Dremio OSS` via `Docker Compose`. So, we need to prepare the `Docker compose` file with following content:
```yaml
version: "3"
services:
  dremio:
    image: dremio/dremio-oss:24.2.5
    ports:
      - 9047:9047 # UI
      - 31010:31010 # ODBC clients
      - 32010:32010 # Arrow Flight clients
      - 2181:2181   # ZooKeeper
      - 45678:45678 # internode communication
    volumes:
      - /data/dremio/data/:/opt/dremio/data/
      - /data/dremio/conf/:/opt/dremio/conf/
    restart: unless-stopped
    networks:
      local_internal:
        ipv4_address: 172.20.80.2

  mysql:
    image: mysql:latest
    # NOTE: use of "mysql_native_password" is not recommended: https://dev.mysql.com/doc/refman/8.0/en/upgrading-from-previous-series.html#upgrade-caching-sha2-password
    # (this is just an example, not intended to be a production configuration)
    command: --default-authentication-plugin=mysql_native_password
    restart: always
    ports:
      - 3307:3306
    environment:
      MYSQL_ROOT_PASSWORD: pwd@123
    networks:
      local_internal:
        ipv4_address: 172.20.80.3

networks:
  local_internal:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.80.0/24

```
And you have to prepare a file `dremio.conf` to configure custom properties as well. For example, in this tutorial, we will use local file system to store Dremio's data including job results, downloads, uploads, accelerators, etc.

```yaml
paths: {

  # the local path for dremio to store data.
  local: "/opt/dremio",

  # the distributed path Dremio data including job results, downloads, uploads, etc
  dist: "file://"${paths.local}"/pdfs"

  # location for catalog database (if master node)
  db: ${paths.local}/db,

  spilling: [${paths.local}/spill]

  # storage area for the accelerator cache.
  accelerator: ${paths.dist}/accelerator

  # staging area for json and csv ui downloads
  downloads: ${paths.dist}/downloads

  # stores uploaded data associated with user home directories
  uploads: ${paths.dist}/uploads

  # stores data associated with the job results cache.
  results: ${paths.dist}/results

  # shared scratch space for creation of tables.
  scratch: ${paths.dist}/scratch

}
```
> *NOTE*: In production deployment, you should use distributed file system or storage object such as S3, HDFS, etc. 

> *You have to copy the file `dremio.conf` to the right directory defined in the `Docker compose` file.*

Next step, running following commands to download docker images, install and start components:

```shell
# enter the dremio directory
cd ~/dremio
# copy the custom configuration file into the directory mapped with the Dremio docker
cp dremio.conf /data/dremio/conf/
# run docker compose
docker compose up
```

The Dremio should be started properly. Afterward, you can access the Admin Web UI at the address *http://localhost:9047*.

You have to initialize your account for the first time. For example:
![iniatlize_dremio_account.png](images%2Finiatlize_dremio_account.png)

### Accessing the data with Dremio
Let's begin by creating a new space. Click on the plus sign next to Spaces and add a space called `dev`. This space will contain our views and virtual models that will be created in next steps.
![create_sapce.png](images%2Fcreate_sapce.png)

Next step, we will create a sample source. We will work with the police incidents data stored on S3. Navigate to Samples in the Sources section on the bottom left. Then click on samples.dremio.com:
![add_sample_source.png](images%2Fadd_sample_source.png)

Next step, on `Object Storage` section, we go to the path `Samples > samples.dremio.com > NYC-taxi-trips-iceberg`, then click on button `Format Folder` on left hand side to format the dataset.
![sample_iceberg_dataset.png](images%2Fsample_iceberg_dataset.png)

On next screen, preview sample of the data and click on `Save` button to confirm the format.

![format_iceberg_file.png](images%2Fformat_iceberg_file.png)
Dremio supports many types of files, including Excel, JSON, Parquet, and others. With some file formats there are required configurations (e.g., field delimiter, line delimiter).

### Exploring dataset
Now, you can start to query on the dataset. For example, you can run the following query to preview sample of the dataset:
```sql
SELECT * FROM Samples."samples.dremio.com"."NYC-taxi-trips-iceberg" LIMIT 100
```
![simple_query.png](images%2Fsimple_query.png)

### Saving as View on the working space
Click on `Save View as` button to save the current query as view on your working space such as `dev` with a name `nyc_taxi_trips`:

![save_as_view.png](images%2Fsave_as_view.png)

Now, you can query this view as following commands:
```sql
SELECT * FROM dev."nyc_taxi_trips" LIMIT 100
```
![query_on_dev_space.png](images%2Fquery_on_dev_space.png)


### Accelerating your queries with `Reflections`
#### A paradigm shift for query acceleration: 
*A Reflection is an optimized relational cache of source data that can be used to speed-up data processing*. Dremio's query optimizer can accelerate a query against tables or Views by using one or more Reflections to partially or entirely satisfy that query, eliminating the need to process all of the raw data in the underlying data sources. Queries do not need to reference Reflections directly. Instead, Dremio rewrites queries on the fly to use matching Reflections, delivering near-instantaneous query results and reduced compute cost.

#### Create a Raw reflection for your models
You can create them to accelerate common SQL aggregations or for raw Reflections across table joins or unoptimized data.

Select the `Reflections` tab to enter the reflection configuration. Next step, you can choose to enable either `Raw Reflections` or `Aggregation Reflections`. 

On the `Raw Reflections` tab, click on `Raw Reflections` to enable reflection for the current model. Next, you can click on button `Dataset Settings`⚙️ on the top right hand side to popup a windows to configure a scheduler for reflection.

![reflection_configuration.png](images%2Freflection_configuration.png)

- Refresh methods: Dremio provides two options to refresh data:
  - Full update:
  - Incremental update:
- Refresh policy:
  - Refresh:
    - Never
    - Interval: Hour(s)/ Day(s)/ Week(s) or Now
  - Expire:
    - Never
    - After: Hour(s)/ Day(s)/ Week(s)

You can monitor status of the reflection jobs on the `Jobs` section.

![reflection_job.png](images%2Freflection_job.png)

Click on the `Job ID` link to move to detailed page, where you can find more information about the job, including its status, resource usage, etc. These details are helpful for debuging if needed.

![monitor_detailed_refection_job.png](images%2Fmonitor_detailed_refection_job.png)

#### Creating an Aggregation reflection
On the `Reflections` tab, choose the `Aggregation reflections`, then click on `Aggregation reflections` button to enable reflection. Next, you need to configure the dimensions and metrics for your aggregation model.

![enable_agg_reflection.png](images%2Fenable_agg_reflection.png)
> **NOTE:** You can create multiple reflections for a model as needed. When you run a query that utilizes your base model, Dremio automatically optimizes the query by selecting a suitable reflection to accelerate its execution.

### Combining data from multiple source with Dremio's Federation query
#### Accessing data from OLTP database - MySQL db

![mysql_local_connection.png](images%2Fmysql_local_connection.png)

![mysql_local_connection_reflection_refresh.png](images%2Fmysql_local_connection_reflection_refresh.png)

![mysql_local_connection_metadata.png](images%2Fmysql_local_connection_metadata.png)

#### Federation query
Now, you can write the federation query that combines data from S3 source and MySQL source:

```sql
SELECT * 
FROM (
    SELECT * FROM "mysql-local".dremio."SF_incidents2016"
)
UNION ALL (
    SELECT * FROM "Samples"."samples.dremio.com"."SF_incidents2016.json"
)
```

![federation_query.png](images%2Ffederation_query.png)

Saving the query result as a view in the `dev` space for future use.

![save_as_view_2.png](images%2Fsave_as_view_2.png)

You can save it as script for future reuse as well.

![save_as_script.png](images%2Fsave_as_script.png)

### Adding wiki for your models
Dremio allow you to add a wiki for your model, providing a guide for users on how to utilize your dataset 

![wiki.png](images%2Fwiki.png)

You can add one or many tags/ labels to your model as well.

## Setting up DBT
### Installing dbt core and dbt-dremio
Firstly, we need to install dbt core and dbt-dremio libraries. You should install them in a separate environment. Run the following commands:
```shell
cd dremio
python3 -m venv .env

# install libraries
pip3 install -r requirements.txt
# check the dbt libraries installed properly
dbt --version

# output should be like the content showcased below:
Core:
  - installed: 1.5.9
  - latest:    1.7.2 - Update available!

  Your version of dbt-core is out of date!
  You can find instructions for upgrading here:
  https://docs.getdbt.com/docs/installation

Plugins:
  - dremio: 1.5.0 - Up to date!
```

## Setting up Power BI Desktop
You can download `Power BI` from [here](https://www.microsoft.com/en-us/download/details.aspx?id=58494) or from `Microsoft store` application if you are using Windows OS.


# Building a simple dbt project and visualizing data with Power BI
## Initializing a dbt project
Following steps below to initialize a new dbt project:
1. Run the command dbt init <project_name>.
2. Select `dremio` as the database to use
3. Select one of these options to generate a profile for your project:
   - `software_with_username_password` for working with a Dremio Software cluster and authenticating to the cluster with a `username` and a `password`
   - `software_with_pat` for working with a Dremio Software cluster and authenticating to the cluster with a personal access token

For simplicity, we will utilize the `software_with_username_password` option.

![init_dbt_project.png](images%2Finit_dbt_project.png)

Next, configure the profile for your dbt project.

## Profiles
```yaml
dremio:
  outputs:
    dev:
      dremio_space: dev
      dremio_space_folder: no_schema
      object_storage_path: no_schema
      object_storage_source: $scratch
      user: "{{ env_var('DBT_USER') }}"
      password: "{{ env_var('DBT_PASSWORD') }}"
      port: 9047
      software_host: localhost
      threads: 1
      type: dremio
      use_ssl: false
  target: dev
```

## SF_Incidents model
To create a simple model with name `SF_Incidents` as following query content:

```sql
{{
  config(
    materialized = "table"
  )
}}

SELECT *
FROM (
    SELECT * FROM "mysql-local".dremio."SF_incidents2016"
)
UNION ALL (
    SELECT * FROM "Samples"."samples.dremio.com"."SF_incidents2016.json"
)
```

Run the following commands to generate model:
```shell
cd dbt/dremio
# activate virtual environment
source .env/bin/activate
# run dbt command to generate the model
dbt run --profiles-dir ./ --project-dir ./

# Results
07:59:13  Running with dbt=1.5.9
07:59:14  Registered adapter: dremio=1.5.0
07:59:14  Unable to do partial parsing because profile has changed
07:59:16  [WARNING]: Did not find matching node for patch with name 'SF_incidents2016' in the 'models' section of file 'models/schema.yml'
07:59:16  [WARNING]: Test 'test.dremio.unique_SF_incidents2016_IncidentNum.f8bdb0741d' (models/schema.yml) depends on a node named 'SF_incidents2016' in package '' which was not found
07:59:16  [WARNING]: Test 'test.dremio.not_null_SF_incidents2016_IncidentNum.93bd2780e1' (models/schema.yml) depends on a node named 'SF_incidents2016' in package '' which was not found
07:59:16  [WARNING]: Configuration paths exist in your dbt_project.yml file which do not apply to any resources.
There are 1 unused configuration paths:
- models.dremio.example
07:59:16  Found 1 model, 0 tests, 0 snapshots, 0 analyses, 352 macros, 0 operations, 0 seed files, 0 sources, 0 exposures, 0 metrics, 0 groups
07:59:16
07:59:17  Concurrency: 1 threads (target='dev')
07:59:17
07:55:00  Finished running 1 view model in 0 hours 0 minutes and 1.32 seconds (1.32s).
07:55:00
07:55:00  Completed successfully
07:55:00
07:55:00  Done. PASS=1 WARN=0 ERROR=0 SKIP=0 TOTAL=1
```



## Building a Dashboard
On Details page of your model, click on `Power BI` icon on the top right hand side to download a `.pdids` file.

![detail_page_model.png](images%2Fdetail_page_model.png)
Next, click on downloaded file (for example: `dev.SF_incidents2016.pbids`). This action triggers a Power BI connection configuration pop-up.

Fill the `username` and `password` information, then click on `Connect` button to start connecting and building your dashboard.

![connection_configuration.png](images%2Fconnection_configuration.png)

This is a simple dashboard built on the `SF_Incidents` dataset.

![dashboard.png](images%2Fdashboard.png)

# Conclusion
In this tutorial, we embarked on a journey through the Police Department Incident Reports dataset (2016), exploring its schema and intricacies using Dremio. We unveiled how Dremio serves as a pivotal tool in simplifying complex data operations, from creating models and views to providing guidance through wikis.

Moreover, the integration of tools like DBT for transformation and Power BI for visualization further amplifies the dataset's potential. DBT's role in transforming and modeling data adds a layer of efficiency to the dataset's preparation, enabling cleaner and more structured outputs. Simultaneously, Power BI's robust visualization capabilities breathe life into the dataset, converting insights into impactful visual narratives.

By combining the capabilities of Dremio, DBT, and Power BI, users can unlock the full potential of their datasets. The seamless flow from data preparation with DBT to dynamic visualizations with Power BI, all orchestrated through Dremio's unified platform, empowers users to extract, analyze, and visualize data-driven insights efficiently.

As we conclude, remember that the dataset we explored is a testament to the storytelling power of data. The convergence of these tools opens doors to a world of possibilities in data analysis, informed decision-making, and actionable insights.

Continue harnessing the combined strengths of Dremio, DBT, and Power BI to explore, analyze, and visualize datasets, propelling your journey towards data-driven excellence.

Thank you for joining us on this tutorial expedition!

# Limitations
The following are some limitations according to the subjective opinion of the author, information updated as of the time of writing:
- **Dremio OSS Functionality**: While Dremio Open Source Software (OSS) offers a robust set of features, it may lack certain capabilities present in the Dremio Cloud version. Notably, functionalities such as comprehensive Data Lineage tracking and AI-driven generative capabilities for automated wiki generation might be exclusive to the Cloud version, restricting these advanced features in the OSS.
- **Dremio Arctic Closed Source Nature**: Dremio Arctic, although a powerful addition for managing time-series data, is not open source. This proprietary aspect may limit user accessibility and customization, potentially hindering the integration and extension of Arctic functionalities within specific environments.
- **Dremio DBT Development Stage**: While Dremio DBT holds promise for streamlined data transformation, it might currently face limitations in its maturity level and documentation depth. Users might encounter challenges due to the tool's evolving nature, potentially impacting its ease of use and comprehensive documentation.
- **Maintenance of Dremio OSS on GitHub**: The Dremio OSS project on GitHub may experience comparatively lesser maintenance, potentially impacting the frequency of updates, bug fixes, and community contributions, which could affect the stability and enhancement of the OSS version.

# Reference Documents
[DBT Dremio](https://docs.getdbt.com/docs/core/connect-data-platform/dremio-setup)

[Dremio OSS document](https://docs.dremio.com/current/get-started/)

[Accelerating Queries with Reflections](https://docs.dremio.com/current/sonar/reflections/)

[Administration](https://docs.dremio.com/current/admin/)
