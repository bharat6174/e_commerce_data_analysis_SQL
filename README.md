# e_commerce_data_analysis_SQL

## Project Objective
To perform in depth analysis on the e-commerce dataset in SQL, and further use python for any required visualizations.

## Dataset used
- Dataset: <a href="https://www.kaggle.com/datasets/devarajv88/target-dataset">e-commerce dataset</a>

## Questions
**Basic Queries**<br>
1. Find the top 10 most frequently purchased products.
2. List the number of sellers operating in each state.
3. Find the number of products listed in each category.
4. Find the total sales per category.
5. Calculate the percentage of orders that were paid in installments.


**Intermediate Queries**<br>
1. Calculate the average delivery time (difference between order purchase and delivery) by state.
2. Identify the top 5 product categories with the highest return rate.
3. Find the relationship between installment payments and order value (average order value when paid in installments vs. full payment). Find correlation in Python.
4. Find the average number of products per order, grouped by customer state.
5. Calculate the percentage of total revenue contributed by each product category.


**Advance Queries**<br>
1. Distribute the orders across spend tiers (Very Low, Low, Medium, High, Very High).
2. Find top 5 sellers' market share in each category.
3. Calculate the month-on-month growth rate of total sales. 
4. Calculate the cumulative sales per month for each year.
5. Statewise Delivery performance (Eary, On Time, Late).


## Process
1. Post downloading the dataset archieve(zip file), it is extracted in a seperate folder.
2. Used jupyter notebook to push the tables to SQL server(MySQL localhost used in this project).
3. Fired all the queries in **SQL database** using appropriate **functions, joins, filters, CTEs, windows function, etc.**
4. Running the same queries in jupyter notebook using _mysql connector library_ and viewing the output as a dataframe.
5. Further created any relevant plots like **bar charts, line charts, etc.** using _matplotlib_ and _seaborn library_.

## Conclusion
SQL is used in tandem with python to meet the project objective and perform the required analysis on the e-commerce dataset.
