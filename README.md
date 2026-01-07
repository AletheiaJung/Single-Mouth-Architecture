# Single-Mouth Architecture (SMA)

<div align="center">

### The Data-Sovereign Architecture for the AI Era

> **"Modern layered architecture is too expensive for AI context windows. Return to the essence of data."**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Status: Manifesto](https://img.shields.io/badge/Status-Manifesto-red.svg)]()
[![AI Ready](https://img.shields.io/badge/AI-Native_Architecture-blue)]()
[![WhitePaper](https://img.shields.io/badge/WhitePaper-v2.0-green)]()

[English](#english) | [한국어](#korean)

</div>

---

<a name="english"></a>
## 🌐 English

### The Philosophy: One Mouth is Enough

> *"My mind holds countless memories and ideas, yet I speak through a single mouth. I don't need a new mouth for each memory, a new voice for each idea."*

This is the essence of **Single-Mouth Architecture**.

A system contains many data entities — Users, Orders, Products, Transactions. But it doesn't need a separate "voice" (type definition) for each entity at every layer. **One authoritative voice is enough.** That voice is the Database.

Just as a person's single mouth can express infinite thoughts, a single well-designed database can express all data truths. The layers above — Backend, API, Frontend — don't need their own "mouths." They simply **listen and relay**.

### What is SMA?

**Single-Mouth Architecture (SMA)** is a software methodology that abolishes redundant type declarations across application layers and designates the **Database as the Single Source of Truth (SSOT)**.

### 📚 Documentation

| Document | Description |
|----------|-------------|
| [**WhitePaper (English)**](./WhitePaper_v2_EN.md) | Full technical paper with architecture details |
| [**WhitePaper (한국어)**](./WhitePaper_v2.md) | 전체 기술 백서 (한국어 버전) |

### 🎯 The Problem We Solve

For a single field `User_Name`, modern development requires:

```
Layer 1 - Database:     VARCHAR(50) NOT NULL
Layer 2 - Backend:      public string UserName { get; set; }
Layer 3 - API Spec:     type: string, maxLength: 50
Layer 4 - Frontend:     interface IUser { userName: string }
```

**4 redundant definitions** for ONE piece of data. 

This is like a person growing 4 mouths to say one thing. Absurd, isn't it? We call this **"The Crisis of Multiple Mouths."**

### 💡 The SMA Solution

```
┌─────────────┐     ┌─────────────┐     ┌─────────────────────┐
│   CLIENT    │     │ MIDDLEWARE  │     │     DATABASE        │
│  (Listens)  │────▶│  (Relays)   │────▶│   (Speaks)          │
│             │◀────│             │◀────│  The Single Mouth   │
└─────────────┘     └─────────────┘     └─────────────────────┘
```

**One Mouth is Enough.** The database speaks. Everything else listens.

### 🏛️ Core Principles

| # | Principle | Description |
|---|-----------|-------------|
| 1 | **One Mouth is Enough** | Only DB has authority to define and speak data truth |
| 2 | **Implicit Strictness** | Naming conventions replace type declarations |
| 3 | **Fluid Integrity** | Runtime defense over compile-time illusion |

### 📋 Semantic Naming Protocol

| Suffix/Prefix | Meaning | Auto Behavior |
|---------------|---------|---------------|
| `_DT` | Date/Time | DatePicker, format `YYYY-MM-DD` |
| `_AMT` | Amount | Thousand separators, right-align |
| `_CNT` | Count | Integer only, no negatives |
| `Is_` / `Has_` | Boolean | Checkbox/Toggle |
| `TB_` | Table | Direct access forbidden |
| `USP_` | Stored Procedure | Single entry point |

### 🚀 Why SMA for AI Era?

| Metric | Traditional | SMA | Improvement |
|--------|-------------|-----|-------------|
| Files per Feature | 7 | 2 | -71% |
| Lines of Code | 500 | 150 | -70% |
| AI Context Tokens | 15,000 | 4,500 | -70% |

**Less code = More AI efficiency = Lower costs = Fewer hallucinations**

### 🛡️ Security

SMA security relies on **isolation**, not obscurity:

1. **View Layer Isolation**: Clients only see `USP_` results, never `TB_` directly
2. **Parameter Whitelisting**: SPs reject undefined parameters
3. **Sanitized Metadata**: Structure info never exposed to clients

### ⚠️ Where SMA Fits Best

| ✅ Excellent Fit | ⚠️ Consider Alternatives |
|------------------|--------------------------|
| Enterprise internal systems | Public APIs (use OpenAPI) |
| CRUD business applications | NoSQL-only systems |
| Data analytics / BI | GraphQL-based systems |
| Small to medium teams | Extreme real-time (gaming) |

### 📖 Quick Start

```sql
-- Database: The ONLY mouth that speaks
CREATE PROCEDURE USP_User_Get @User_ID INT
AS
BEGIN
    SELECT User_NM, Reg_DT, Balance_AMT, Is_Active
    FROM TB_User WHERE User_ID = @User_ID
END
```

```csharp
// Backend: Just listens and relays
[HttpGet("user/{id}")]
public async Task<IActionResult> GetUser(int id)
    => Ok(await _db.Execute("USP_User_Get", new { User_ID = id }));
```

```jsx
// Frontend: Just listens and displays
const UserProfile = ({ userId }) => {
  const { data } = useSmartQuery(`/api/user/${userId}`);
  return <AutoForm data={data} />;
};
```

---

<a name="korean"></a>
## 🇰🇷 한국어

### 철학: 입은 하나면 족하다

> *"내 머리 속에는 수많은 기억과 아이디어가 있다. 하지만 나는 하나의 입으로 말한다. 기억마다 새로운 입이 필요하지 않고, 아이디어마다 새로운 목소리가 필요하지 않다."*

이것이 **Single-Mouth Architecture**의 본질입니다.

시스템에는 많은 데이터 엔티티가 존재합니다 — 사용자, 주문, 상품, 거래. 하지만 각 엔티티가 각 계층에서 별도의 "목소리"(타입 정의)를 가질 필요는 없습니다. **하나의 권위 있는 목소리면 충분합니다.** 그 목소리는 데이터베이스입니다.

사람의 하나의 입이 무한한 생각을 표현할 수 있듯이, 잘 설계된 하나의 데이터베이스가 모든 데이터의 진실을 표현할 수 있습니다. 그 위의 계층들 — Backend, API, Frontend — 은 자신만의 "입"이 필요 없습니다. 그저 **듣고 전달**하면 됩니다.

### SMA란?

**Single-Mouth Architecture (SMA)**는 애플리케이션 계층의 중복 타입 선언을 제거하고, **데이터베이스를 유일한 진실의 원천(SSOT)**으로 지정하는 소프트웨어 방법론입니다.

### 📚 문서

| 문서 | 설명 |
|------|------|
| [**WhitePaper (한국어)**](./WhitePaper_v2.md) | 전체 기술 백서 |
| [**WhitePaper (English)**](./WhitePaper_v2_EN.md) | Full technical paper |

### 🎯 우리가 해결하는 문제

하나의 필드 `User_Name`을 처리하기 위해 현대 개발에서는:

```
계층 1 - Database:     VARCHAR(50) NOT NULL
계층 2 - Backend:      public string UserName { get; set; }
계층 3 - API Spec:     type: string, maxLength: 50
계층 4 - Frontend:     interface IUser { userName: string }
```

**하나의 데이터**에 **4개의 중복 정의**.

이것은 마치 하나의 말을 하기 위해 4개의 입을 만드는 것과 같습니다. 우스꽝스럽지 않습니까? 우리는 이것을 **"다중 발화의 위기"**라 부릅니다.

### 💡 SMA 해결책

```
┌─────────────┐     ┌─────────────┐     ┌─────────────────────┐
│   CLIENT    │     │ MIDDLEWARE  │     │     DATABASE        │
│   (듣는다)   │────▶│  (전달한다)  │────▶│     (말한다)         │
│             │◀────│             │◀────│   하나의 입          │
└─────────────┘     └─────────────┘     └─────────────────────┘
```

**입은 하나면 족하다.** 데이터베이스가 말한다. 나머지는 듣는다.

### 🏛️ 핵심 원칙

| # | 원칙 | 설명 |
|---|------|------|
| 1 | **입은 하나면 족하다** | DB만이 데이터의 진실을 정의하고 말할 권한을 가진다 |
| 2 | **암묵적 엄격성** | 네이밍 규약이 타입 선언을 대체한다 |
| 3 | **유동적 무결성** | 컴파일 타임의 환상보다 런타임 방어가 현실적이다 |

### 📋 의미론적 명명 프로토콜

| 접미어/접두어 | 의미 | 자동 동작 |
|---------------|------|-----------|
| `_DT` | 날짜/시간 | DatePicker, `YYYY-MM-DD` 포맷 |
| `_AMT` | 금액 | 천 단위 콤마, 우측 정렬 |
| `_CNT` | 개수 | 정수만, 음수 불허 |
| `Is_` / `Has_` | Boolean | Checkbox/Toggle |
| `TB_` | 테이블 | 직접 접근 금지 |
| `USP_` | 저장 프로시저 | 단일 진입점 |

### 🚀 AI 시대에 왜 SMA인가?

| 지표 | 기존 방식 | SMA | 개선율 |
|------|-----------|-----|--------|
| 기능 당 파일 수 | 7개 | 2개 | -71% |
| 코드 라인 수 | 500줄 | 150줄 | -70% |
| AI 컨텍스트 토큰 | 15,000 | 4,500 | -70% |

**적은 코드 = 높은 AI 효율 = 낮은 비용 = 적은 환각**

---

## 👤 Author

**Aletheia Jung**  
System Architect

- 📧 Email: aletheia.jung.arch@gmail.com
- 🐙 GitHub: [@AletheiaJung](https://github.com/AletheiaJung)

---

## 📜 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

---

## 🤝 Contributing

Contributions, issues, and feature requests are welcome!

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## ⭐ Support

If you find this methodology valuable, please consider:

- ⭐ **Starring** this repository
- 🔄 **Sharing** with your network
- 💬 **Discussing** in issues or on social media

---

<div align="center">

**"Simplicity is the ultimate sophistication."**  
*- Leonardo da Vinci*

---

Made with ❤️ by [Aletheia Jung](https://github.com/AletheiaJung)

</div>
