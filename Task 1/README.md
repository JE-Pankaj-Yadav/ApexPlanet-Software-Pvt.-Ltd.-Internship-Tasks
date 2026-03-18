# 🛒 Customer Shopping Data Cleaning Project

## 📌 Project Overview
This project is about cleaning customer shopping data using SQL.  
Raw data usually has mistakes, missing values, and wrong formats.  
So, we clean it to make it ready for analysis.

---

## 📂 Files in This Project

1️⃣ **Cleaned Dataset (CSV File)**  
- Contains final cleaned customer shopping data  
- Ready for analysis, dashboards, and reports  

2️⃣ **Data Dictionary (CSV File)**  
- Explains the meaning of each column  
- Helps users understand the dataset easily  

3️⃣ **SQL Cleaning Script (.sql file)**  
- Contains step-by-step SQL queries  
- Used to clean and prepare the raw data  

---

## ⚙️ What This Project Does

The SQL script performs these tasks:

### ✅ Step 1: Create Table
Creates a table to store raw shopping data.

### ✅ Step 2: Fix Data Types
Changes wrong data formats:
- Text → Numbers
- Text → Date format

### ✅ Step 3: Find Missing Values
Checks if important data is missing.

### ✅ Step 4: Remove Duplicate Records
Deletes repeated invoice entries.

### ✅ Step 5: Remove Wrong Data
Deletes:
- Invalid age values
- Negative price or quantity
- Future dates

### ✅ Step 6: Clean Text Data
Standardizes gender column:
- "m", "M" → MALE
- "f", "F" → FEMALE
- Removes extra spaces

### ✅ Step 7: Remove Price Outliers
Removes unusually high prices using statistical rule.

### ✅ Step 8: Create New Column
Adds **Total Amount** column:

Total Amount = Price × Quantity

### ✅ Step 9: Export Cleaned Data
Final cleaned data is exported to CSV file.

---

## 🎯 Purpose of This Project
- Make raw data clean and usable
- Improve data quality
- Prepare dataset for:
  - Data Analysis
  - Power BI Dashboards
  - Reports
  - Business Insights

---

## 🧰 Tools Used
- SQL
- PostgreSQL / MySQL (any SQL database)
- Excel / Power BI (for analysis)

---

## 👨‍💻 Who Can Use This Project?
- Data Analyst Beginners
- SQL Learners
- Students
- Internship Projects
- Portfolio Projects

---

## 🚀 How to Use

1. Import raw dataset into SQL database
2. Run the SQL cleaning script
3. Export cleaned data
4. Use cleaned data for analysis

---

## 📈 Output
You get a **clean, structured, and analysis-ready dataset**.