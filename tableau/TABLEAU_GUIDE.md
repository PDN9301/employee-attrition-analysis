# Building the Employee Attrition Dashboard in Tableau Public

**Time:** about 60–90 minutes. **Cost:** free.
**You'll need:** [Tableau Public](https://public.tableau.com/app/discover) (free desktop app) and `employee_attrition_tableau.csv` from this folder.

The CSV was produced by `sql/tableau_extract.sql`. It has one row per employee, with labels and bands already added, so only a few calculated fields are needed.

---

## 1. Connect to the data

1. Open Tableau Public, then go to **Connect → To a File → Text file** and select `employee_attrition_tableau.csv`.
2. In the data pane, make sure these fields are **Dimensions** (drag them above the line or right-click → *Convert to Dimension*): `Employee ID`, `Projects`, `Years at Company`, `Salary Rank`.
3. Right-click `Salary Level` → **Sort** → *Sort by field* → `Salary Rank` (ascending), so the order is Low → Medium → High.

## 2. Create calculated fields

**Analysis → Create Calculated Field** for each:

| Name | Formula | Format |
|---|---|---|
| `Headcount` | `COUNT([Employee ID])` | Number, 0 decimals, thousands separator |
| `Employees Left` | `SUM([Left (1/0)])` | Number, 0 decimals |
| `Attrition Rate` | `SUM([Left (1/0)]) / COUNT([Employee ID])` | Percentage, 1 decimal |
| `Company Attrition Rate` | `{ FIXED : SUM([Left (1/0)]) / COUNT([Employee ID]) }` | Percentage, 1 decimal |
| `Above Company Avg` | `[Attrition Rate] > MIN([Company Attrition Rate])` | (used for color) |

`Company Attrition Rate` is a **Level of Detail (LOD) expression**. It always returns the company-wide rate (23.8%), no matter what is on the view, so it works as a benchmark line.

## 3. Build the worksheets

Write each title as a finding, not just a label. Recruiters read titles first.

### Sheet 1: KPI tiles (make 3 small sheets)
- **KPI Headcount**: drag `Headcount` to **Text**. Format it large (28pt, bold) and add a "Employees" caption on the line below.
- **KPI Left**: same steps with `Employees Left`.
- **KPI Rate**: same steps with `Attrition Rate`.

### Sheet 2: Attrition by Department
- Rows: `Department` · Columns: `Attrition Rate`
- Sort descending (toolbar sort button).
- Color: `Above Company Avg` (True = orange, False = gray).
- Detail: `Company Attrition Rate`. Then **Analytics pane → Reference Line** → Entire Table → Value: `MIN(Company Attrition Rate)` → Label: *Custom* "Company avg <Value>".
- Label: `Attrition Rate`.
- Title: **"HR and Accounting lose staff fastest; Management and R&D retain best"**

### Sheet 3: Workload curve
- Columns: `Projects` · Rows: `Attrition Rate` (Bar) and `AVG(Avg Monthly Hours)`.
- Right-click the second axis → **Dual Axis**. Set the marks for `Avg Monthly Hours` to **Line**.
- Title: **"Attrition spikes at both ends: 66% with 2 projects, 100% with 7"**

### Sheet 4: Satisfaction × Evaluation heat map
- Columns: `Satisfaction Band` · Rows: `Evaluation Band` (descending, so high performers are on top)
- Marks: **Square**. Color: `Attrition Rate` (Orange sequential). Label: `Attrition Rate`.
- Tooltip: add `Headcount` and `Employees Left`.
- Title: **"Burned-out high performers and disengaged under-performers drive turnover"**

### Sheet 5: Attrition by Tenure
- Columns: `Years at Company` · Rows: `Attrition Rate` (Bar). Label the bars.
- Title: **"Attrition peaks in year 5 (57%), then drops to zero after year 6"**

### Sheet 6: Attrition by Salary
- Columns: `Salary Level` · Rows: `Attrition Rate` (Bar). Label the bars.
- Title: **"Low-paid employees leave 4.5× more than high-paid"**

### Sheet 7: Who is leaving?
- Rows: `Segment` · Columns: `Employees Left`. Sort descending.
- Filter `Segment` to exclude "Other" if you want to focus on the three groups.
- Title: **"Three groups make up 94% of leavers"**

## 4. Assemble the dashboard

1. **Dashboard → New Dashboard.** Size: *Fixed*, 1200 × 1000 (or *Automatic*).
2. Layout:

```
┌──────────────────────────────────────────────────────────────┐
│  Employee Attrition Dashboard          [Department ▼] [Salary ▼] │
├───────────────┬────────────────┬─────────────────────────────┤
│  Headcount    │  Employees Left│  Attrition Rate             │
├───────────────┴────────────────┼─────────────────────────────┤
│  Attrition by Department       │  Workload curve             │
├────────────────────────────────┼──────────────┬──────────────┤
│  Satisfaction × Evaluation     │  Tenure      │  Salary      │
│  heat map                      │              │              │
├────────────────────────────────┴──────────────┴──────────────┤
│  Who is leaving? (segments)                                   │
└──────────────────────────────────────────────────────────────┘
```

3. **Filters:** on any sheet, right-click `Department` and `Salary Level` → *Show Filter*. Then click each filter's ▼ menu → **Apply to Worksheets → All Using This Data Source**.
4. **Interactivity:** go to **Dashboard → Actions → Add Action → Filter**. Set Source sheet = *Attrition by Department*, Run on = *Select*, Targets = all other sheets. Now clicking a department filters the whole dashboard.
5. Add a short text box under the title: *"14,999 employees · SQL-prepared data · Click a department to filter"*.

## 5. Publish and link it

1. **File → Save to Tableau Public**, and name it `Employee Attrition Dashboard`.
2. Copy the URL from your browser.
3. Take a screenshot of the dashboard, save it as `tableau/dashboard.png` in this repo, and add these lines to the project README under "Tableau Dashboard":

```markdown
[![Employee Attrition Dashboard](tableau/dashboard.png)](https://public.tableau.com/app/profile/<your-profile>/viz/<your-dashboard>)
```

4. Put the Tableau Public link on your resume, next to the GitHub link for this project.
