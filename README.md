

# Job Automation in Manufacturing Module (Oracle ERP)

## Overview
This project automates the **job creation process** within the **Manufacturing Module** of **Oracle ERP**. Traditionally, users had to manually create jobs using the **WIP Discrete Jobs** interface. This project streamlines the entire process, allowing users to create **parent and child assembly jobs** from a **single window**, reducing manual work and increasing efficiency.  

By leveraging **BOM (Bill of Materials) explosion**, the system ensures that all parent and child assemblies are correctly accounted for and jobs are created with the required quantities while considering existing job data in the system.  

## **Key Features**  
✅ **Automated Job Creation**: Users can create jobs for both **parent and child assemblies** without navigating multiple screens.  
✅ **Sales Order Integration**: Retrieves and displays all sales orders within a given **Scheduled Ship Date (SSD) range**.  
✅ **BOM Explosion Processing**: Automatically breaks down the BOM structure to create jobs for all required subassemblies.  
✅ **Real-time Data Validation**: Checks **open demand, excess quantity, existing jobs**, and **pending quantities** before job creation.  
✅ **User-friendly UI**: Displays **all required data** in a structured form, allowing users to review and make informed decisions.  
✅ **Minimized Errors & Manual Effort**: Eliminates the risk of missing components or incorrect job quantities.  

---

## How It Works  
1. User Inputs 
   - Users enter the **From Date** and **To Date** for the **Scheduled Ship Date (SSD)** range.  
   - Select a **Sales Order** or **Planning Category** (Optional).  
   - Optionally filter jobs using the **Line Number** or **'Club CCA Job'** checkbox.  
   - Click **Find** to retrieve relevant sales orders.  

2. Sales Order & Job Verification  
   - The form displays all **sales orders** that match the input criteria.  
   - Checks for existing **jobs already created** against those sales orders.  
   - Displays pending job quantities and **maximum job quantities allowed**.  

3. Job Creation for Parent Assemblies
   - Users can split jobs using the **Split Assembly** option.  
   - Allows scheduling job completion based on required quantities.  
   - Users can **select** a job and proceed with **job creation**.  

4. Child Assembly Processing (BOM Explosion)  
   - The system automatically breaks down the **Bill of Materials (BOM)** to identify **child assemblies**.  
   - Displays child items with job quantities, open demand, on-hand quantities, and existing job data.  
   - Checks for **excess or shortage of job quantities** and adjusts job creation accordingly.  
   - Users can **modify quantities** before scheduling jobs.  

5. Job Validation & Execution  
   - Clicking **Validate** ensures all required inputs are met.  
   - Clicking **Create Job** executes the job creation process for parent and child assemblies in Oracle ERP.  
   - Logs all actions and updates relevant tables.  

6. Error Handling & User Actions  
   - Users can **Cancel** at any stage.  
   - If errors are detected (e.g., missing BOM components, insufficient on-hand quantity), they are displayed for user action.  

---

## Technology Stack  
- **Oracle ERP (Manufacturing Module)**  
- **Oracle Forms & Reports**  
- **PL/SQL (Stored Procedures, Packages, Triggers)**  
- **BOM Explosion Algorithms**  
- **Workflow Automation**  

---

## Business Impact  
🚀 **Faster Job Creation**: Reduces manual job creation time significantly.  
📉 **Eliminates Data Entry Errors**: Automated checks ensure data integrity.  
⏳ **Saves Hours of Manual Work**: Reduces workload for production planners.  
🔄 **Seamless Integration with Oracle ERP**: Ensures consistency with existing manufacturing data.  
📊 **Improves Decision-Making**: Provides clear insights on job requirements before execution.  

