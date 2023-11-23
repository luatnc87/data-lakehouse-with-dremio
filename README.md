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
SELECT * FROM "NYC-taxi-trips-iceberg" LIMIT 100
```
![simple_query.png](images%2Fsimple_query.png)


### Accelerator for the queries


## Setting up DBT

## Setting up Power BI Desktop

# Build a simple data pipeline


# Conclusion




