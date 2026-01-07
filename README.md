# SMA Reference Implementation

> **Single-Mouth Architecture (SMA) 참조 구현**

이 폴더는 SMA의 핵심 개념을 실제 코드로 구현한 참조 예제입니다.

---

## 📁 Structure

```
samples/
├── database/
│   └── SMA_Schema.sql      # MSSQL 스키마 + 저장 프로시저
├── backend/
│   └── SmaWebApi.cs        # C# .NET 8 WebAPI
├── frontend/
│   └── SmaReact.tsx        # React + TypeScript
└── README.md               # This file
```

---

## 🚀 Quick Start

### 1. Database Setup (MSSQL)

```bash
# SQL Server Management Studio 또는 Azure Data Studio에서 실행
sqlcmd -S localhost -d master -i database/SMA_Schema.sql
```

**생성되는 객체:**

| Type | Name | Description |
|------|------|-------------|
| Table | `TB_User` | 사용자 테이블 |
| Table | `TB_Order` | 주문 테이블 |
| Table | `TB_OrderDetail` | 주문 상세 테이블 |
| SP | `USP_User_Get` | 사용자 단건 조회 |
| SP | `USP_User_List` | 사용자 목록 조회 |
| SP | `USP_User_Create` | 사용자 생성 |
| SP | `USP_User_Update` | 사용자 수정 |
| SP | `USP_User_Delete` | 사용자 삭제 |
| SP | `USP_Payment_Process` | 결제 처리 (Exception Sovereignty 예제) |
| SP | `USP_Order_Create` | 주문 생성 |
| Function | `UFN_GetAge` | 나이 계산 |
| Function | `UFN_FormatAmount` | 금액 포맷팅 |
| View | `VW_UserSummary` | 사용자 요약 뷰 |

### 2. Backend Setup (.NET 8)

```bash
cd backend
dotnet new webapi -n SmaDemo
# SmaWebApi.cs 내용을 프로젝트에 복사
dotnet add package Microsoft.Data.SqlClient
dotnet run
```

**appsettings.json:**
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=localhost;Database=SMA_Demo;Trusted_Connection=True;TrustServerCertificate=True;"
  }
}
```

### 3. Frontend Setup (React)

```bash
cd frontend
npx create-react-app sma-demo --template typescript
# SmaReact.tsx 내용을 src/에 복사
npm start
```

---

## 🎯 Key Concepts Demonstrated

### 1. Semantic Naming Protocol

```sql
-- 컬럼 명명 규칙이 UI 동작을 결정
User_NM         -- String → Text Input
Balance_AMT     -- Currency → 천 단위 콤마, 우측 정렬
Reg_DT          -- Date → DatePicker
Is_Active       -- Boolean → Checkbox
```

### 2. Self-Describing Packet

```json
{
  "meta": {
    "columns": ["User_NM", "Balance_AMT", "Reg_DT", "Is_Active"],
    "types": ["string", "currency", "date", "boolean"],
    "constraints": {
      "User_NM": { "maxLength": 50, "required": true },
      "Balance_AMT": { "format": "#,##0" }
    }
  },
  "data": [["홍길동", 1500000, "2025-01-07", true]]
}
```

### 3. Exception Sovereignty

```sql
-- DB에서 구체적인 에러 메시지 생성
THROW 51100, N'잔액이 500원 부족합니다. 현재 잔액: 1,500원', 1;
```

```javascript
// 프론트엔드에서 그대로 표시
catch (err) {
  alert(err.message); // "잔액이 500원 부족합니다. 현재 잔액: 1,500원"
}
```

### 4. Zero-Logic Backend

```csharp
// Controller에 비즈니스 로직 없음
[HttpGet("{id}")]
public async Task<IActionResult> Get(int id)
{
    var result = await _db.ExecuteAsync("USP_User_Get", new { User_ID = id });
    return Ok(result);  // 그냥 전달만
}
```

### 5. Auto-Binding Frontend

```jsx
// interface 선언 없이 자동 폼 생성
<AutoForm data={data} meta={meta} onSubmit={handleSave} />

// 메타데이터 기반 자동 그리드
<AutoGrid data={users} meta={meta} onRowClick={handleSelect} />
```

---

## 📋 API Endpoints

| Method | Endpoint | SP | Description |
|--------|----------|-----|-------------|
| GET | `/api/users/{id}` | `USP_User_Get` | 사용자 조회 |
| GET | `/api/users` | `USP_User_List` | 사용자 목록 |
| POST | `/api/users` | `USP_User_Create` | 사용자 생성 |
| PUT | `/api/users/{id}` | `USP_User_Update` | 사용자 수정 |
| DELETE | `/api/users/{id}` | `USP_User_Delete` | 사용자 삭제 |
| POST | `/api/payments` | `USP_Payment_Process` | 결제 처리 |
| POST | `/api/orders` | `USP_Order_Create` | 주문 생성 |

---

## 🔍 Testing Exception Sovereignty

```bash
# 1. 사용자 잔액 확인
curl http://localhost:5000/api/users/1

# 2. 잔액보다 큰 금액으로 결제 시도
curl -X POST http://localhost:5000/api/payments \
  -H "Content-Type: application/json" \
  -d '{"User_ID": 1, "Amount_AMT": 9999999}'

# 결과: {"message": "잔액이 8,499,999원 부족합니다. 현재 잔액: 1,500,000원", "code": 51100}
```

---

## 📜 License

MIT License - [Aletheia Jung](https://github.com/AletheiaJung)
