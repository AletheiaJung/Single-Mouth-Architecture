# Single-Mouth Architecture (SMA)
**The Immutable Truth of Enterprise Data Integrity**

> **Author:** Aletheia Jung (System Engineer & Developer with 30 Years of Experience)  
> **Date:** 2026-01-07  
> **Version:** 1.0.0

---

## 0. Abstract (초록)

현대 소프트웨어 개발 트렌드는 ORM(Object-Relational Mapping)과 애플리케이션 레벨의 로직 처리에 집중하며, 데이터베이스를 단순한 저장소(Storage)로 격하시켰다. 그러나 이러한 접근 방식은 데이터 무결성 훼손, 쿼리 성능 저하, 그리고 유지보수의 파편화를 초래했다.

본 논문은 이러한 복잡성을 제거하고 시스템의 본질인 '데이터(Data)'로 회귀하는 **Single-Mouth Architecture (SMA)**를 제안한다. SMA는 모든 비즈니스 로직과 데이터 처리를 데이터베이스의 저장 프로시저(Stored Procedure)라는 '단일 창구(Single Mouth)'로 위임하며, 애플리케이션 계층(C#, Java 등)은 순수한 매개체 역할만을 수행한다. 이는 30년간의 실무 경험을 통해 검증된 가장 견고하고 실용적인 엔터프라이즈 아키텍처이다.

---

## 1. Introduction: The Crisis of Logic Dispersion (서론)

개발 언어와 프레임워크가 발전할수록 시스템은 비대해졌다. 비즈니스 로직은 프론트엔드, 백엔드 API, 그리고 데이터베이스 곳곳에 분산(Dispersion)되어 있다. 이로 인해 다음과 같은 문제가 발생한다.

1.  **성능 저하:** 애플리케이션에서 데이터를 가져와 가공(Loop, Filter)하는 과정에서 불필요한 I/O와 메모리 낭비 발생.
2.  **보안 취약점:** 인라인 SQL(Inline SQL) 사용으로 인한 SQL Injection 위험 및 쿼리 계획(Plan) 최적화 실패.
3.  **유지보수의 난해함:** 데이터 구조 변경 시, 컴파일이 필요한 애플리케이션 소스를 수정하고 재배포해야 하는 비효율성.

**Single-Mouth Architecture**는 "데이터 처리는 데이터를 가장 잘 아는 DB 엔진이 수행해야 한다"는 원칙 아래, 이 모든 문제를 해결한다.

---

## 2. Core Philosophy: Aletheia (핵심 철학)

**'Aletheia(알레테이아)'**는 그리스어로 '진리' 또는 '은폐되지 않음'을 뜻한다. 시스템에서 은폐되지 않아야 할 유일한 진리는 **데이터(Data)** 그 자체다.

### 2.1. Logic Belongs to Data (로직의 귀속)
데이터를 가공하는 규칙(Rule)은 데이터가 저장된 곳에 함께 존재해야 한다. C#이나 Java 코드는 휘발성이지만, DB에 저장된 프로시저와 데이터는 영속적이다.

### 2.2. The Single Mouth (단일 창구)
외부(Client/App)에서 데이터에 접근하는 길은 오직 하나, **저장 프로시저(Stored Procedure)**라는 입(Mouth)을 통해서만 가능하다. 뒷문(Inline SQL)은 허용하지 않는다.

---

## 3. Implementation Standards (구현 표준)

SMA를 구현하기 위해서는 엄격한 명명 규칙(Naming Convention)과 역할 분담이 필수적이다.

### 3.1. Concrete Naming (구체적 명명법)
모호한 이름이나 예약어(Reserved Word) 충돌은 시스템의 암이다. 모든 객체는 접두어(Prefix)를 통해 그 정체성을 명확히 드러내야 한다.

* **Tables:** `TB_` (예: `TB_Member`, `TB_ProductLog`)
* **Views:** `VW_` (예: `VW_DailySales`)
* **Stored Procedures:** `USP_` (User Stored Procedure, 예: `USP_MemberJoin`)
* **User Functions:** `UFN_` (User Function, 예: `UFN_GetAge`)

### 3.2. Action Oriented Naming (행위 중심 명명)
메소드나 SP의 이름은 **[객체(Object) + 동사(Verb)]** 형식을 따른다. 이는 데이터베이스 인덱스 정렬과 유사하게, 관련된 객체들의 기능을 그룹화하여 가독성을 극대화한다.

* *Bad:* `GetMember()`, `CreateOrder()`, `UpdateStock()`
* *Good (SMA):* `MemberGet()`, `OrderCreate()`, `StockUpdate()`

### 3.3. Zero-Logic Middleware (무로직 미들웨어)
C# (WebAPI) 등의 미들웨어는 다음 역할만 수행한다.
1.  클라이언트 요청 수신.
2.  `USP_` 호출 및 파라미터 전달.
3.  결과(JSON/XML) 반환.
* **금지 사항:** 미들웨어 단에서의 데이터 필터링, 정렬, 연산, 인라인 SQL 작성.

---

## 4. Architecture Diagram (아키텍처 구조)

```text
[ Client Layer ]      [ Middleware Layer ]       [ Data Layer (The Core) ]
(React, Mobile)       (C# WebAPI)                (MSSQL Server)
      |                       |                          |
      |   Request (JSON)      |   Call USP_Name          |
      +---------------------> | -----------------------> |  1. Validate (UFN_)
                              |                          |  2. Transaction (Begin/Commit)
                              |                          |  3. Business Logic (CRUD)
      <---------------------+ | <----------------------- |  4. Return Result
          Response            |      Result Set          |
