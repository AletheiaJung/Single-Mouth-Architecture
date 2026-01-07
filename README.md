# Single-Mouth Architecture (SMA)
### : The Data-Sovereign Architecture for the AI Era

> **"Modern layered architecture is too expensive for AI context windows. Return to the essence of data."**
> *(현대의 계층형 아키텍처는 AI의 컨텍스트 윈도우에 너무 비싼 비용을 요구합니다. 데이터의 본질로 돌아가십시오.)*

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Status: Concept](https://img.shields.io/badge/Status-Manifesto-red.svg)]()
[![AI Ready](https://img.shields.io/badge/AI-Native_Architecture-blue)]()

---

## 1. The Crisis of "Multiple Mouths" (문제 제기)

In modern software engineering, we define the same data too many times.
For a single field `User_Name`, we write:
1.  **Database:** `VARCHAR(50)`
2.  **Backend:** `class UserDTO { string UserName }`
3.  **API:** Swagger/OpenAPI Spec
4.  **Frontend:** `interface IUser { userName: string }`

We call this **"The Crisis of Multiple Mouths."**
The truth (Data) is one, but the mouths describing it are many. This redundancy increases maintenance costs, slows down development, and most importantly, **wastes AI tokens** by feeding repetitive context.

We are repeating the mistakes of CORBA and WSDL by wrapping flexible JSON with rigid TypeScript layers. It is time to stop.

---

## 2. Core Philosophy: Data Sovereignty (핵심 철학)

**Single-Mouth Architecture (SMA)** abolishes all intermediate type declarations.
We believe that the **Database** is the Single Source of Truth (SSOT).

### The 3 Principles
1.  **One Mouth is Enough:** Source code has no right to redefine data. It should only transport it.
2.  **Implicit Strictness:** Replace explicit type files (`.d.ts`) with **Semantic Naming Protocols**.
3.  **Fluid Integrity:** Integrity is enforced by the Database and Stored Procedures, not by the compiler.

---

## 3. How It Works: Implicit Strictness (작동 원리)

Instead of writing types, we follow a strict **Naming Convention**. The system (Middleware & UI) automatically infers rules from these names at runtime.

### Semantic Naming Protocol (Example)

| Suffix / Prefix | Meaning | System Behavior (Auto-Binding) |
| :--- | :--- | :--- |
| **`_DT`** | Date/Time | Renders DatePicker, Formats `YYYY-MM-DD` |
| **`_AMT`** | Amount (Currency) | Renders NumberInput, Formats `1,000`, Right-align |
| **`Is_` / `Has_`** | Boolean | Renders Checkbox or Toggle Switch |
| **`_Rate`** | Percentage | Formats `%`, Validates 0-100 range |
| **`TB_`** | Physical Table | Direct access forbidden (Internal use only) |
| **`USP_`** | User Stored Proc | The only allowed entry point for Logic |

---

## 4. Security Architecture (보안)

Critics argue that exposing DB structure is dangerous. SMA counters this with **"Isolation via Stored Procedures."**

1.  **View Layer Isolation:**
    Clients never access `TB_` (Tables) directly. They only see the **Virtual Result** returned by `USP_`. We use Aliases in SPs to hide physical column names if necessary.

2.  **Strict Parameter Whitelisting:**
    Mass Assignment attacks are impossible because SPs only accept defined parameters. Any undefined input is rejected by the DB engine immediately.

---

## 5. AI-Native Optimization (AI 최적화)

**This is why SMA is essential for the future.**

### 📉 Cost Reduction (Tokenomics)
By removing DTOs, Interfaces, and Boilerplate code, SMA reduces the codebase by **70%**. This allows AI to load **3x more logic** into its Context Window, drastically reducing API costs and "Hallucinations."

### 🧠 Zero-Impedance Analytics
Data is not trapped in application code. Semantic naming (`_AMT`, `_Rate`) serves as **High-Quality Labels** for AI Agents.
* **Result:** An AI Data Analyst can directly query and interpret the database without needing ETL or code parsing.

---

## 6. Comparison (비교)

| Feature | Current Stack (TypeScript/JPA) | SMA (Single-Mouth) |
| :--- | :--- | :--- |
| **Type Definition** | Manual (4 layers) | **None (Inferred from DB)** |
| **Refactoring** | Heavy (Edit 4 files) | **Instant (Edit SP only)** |
| **Validation** | Distributed (Front/Back/DB) | **Centralized (DB/SP)** |
| **AI Context** | Low Density (Noise) | **High Density (Signal)** |
| **Philosophy** | "Code controls Data" | **"Data controls Code"** |

---

## 7. Getting Started (Example)

### Database (The Only Definition)
```sql
-- The Logic and Validation exist HERE only.
CREATE PROCEDURE USP_GetUserInfo
AS
BEGIN
    SELECT 
        User_NM,        -- String
        Reg_DT,         -- Date (Auto-formatted by UI)
        Balance_AMT,    -- Money (Auto-formatted by UI)
        Is_Active       -- Boolean (Auto-checkbox by UI)
    FROM TB_User
END
