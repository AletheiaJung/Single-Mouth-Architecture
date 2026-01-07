-- ============================================
-- Single-Mouth Architecture (SMA)
-- Database Layer - Reference Implementation
-- ============================================
-- Author: Aletheia Jung
-- Version: 1.0.0
-- Database: Microsoft SQL Server 2019+
-- ============================================

-- ============================================
-- 1. TABLE CREATION (TB_ Prefix)
-- ============================================

-- 사용자 테이블
CREATE TABLE TB_User (
    User_ID         INT IDENTITY(1,1) NOT NULL,
    User_NM         NVARCHAR(50)      NOT NULL,      -- _NM: Name/String
    Email_NM        NVARCHAR(100)     NOT NULL,      -- _NM: Name/String
    Balance_AMT     DECIMAL(18,2)     NOT NULL DEFAULT 0,  -- _AMT: Money
    Point_CNT       INT               NOT NULL DEFAULT 0,  -- _CNT: Count
    Birth_DT        DATE              NULL,          -- _DT: Date
    Reg_DT          DATETIME          NOT NULL DEFAULT GETDATE(),  -- _DT: DateTime
    Mod_DT          DATETIME          NULL,          -- _DT: DateTime
    Is_Active       BIT               NOT NULL DEFAULT 1,  -- Is_: Boolean
    Is_Premium      BIT               NOT NULL DEFAULT 0,  -- Is_: Boolean
    Del_YN          CHAR(1)           NOT NULL DEFAULT 'N', -- _YN: Yes/No Flag
    CONSTRAINT PK_User PRIMARY KEY (User_ID)
);

-- 주문 테이블
CREATE TABLE TB_Order (
    Order_ID        INT IDENTITY(1,1) NOT NULL,
    User_ID         INT               NOT NULL,
    Order_DT        DATETIME          NOT NULL DEFAULT GETDATE(),
    Total_AMT       DECIMAL(18,2)     NOT NULL,
    Discount_Rate   DECIMAL(5,2)      NOT NULL DEFAULT 0,  -- _Rate: Percentage
    Status_CD       VARCHAR(20)       NOT NULL DEFAULT 'PENDING', -- _CD: Code
    Ship_Addr_DESC  NVARCHAR(500)     NULL,          -- _DESC: Description
    Del_YN          CHAR(1)           NOT NULL DEFAULT 'N',
    CONSTRAINT PK_Order PRIMARY KEY (Order_ID),
    CONSTRAINT FK_Order_User FOREIGN KEY (User_ID) REFERENCES TB_User(User_ID)
);

-- 주문 상세 테이블
CREATE TABLE TB_OrderDetail (
    Detail_ID       INT IDENTITY(1,1) NOT NULL,
    Order_ID        INT               NOT NULL,
    Product_NM      NVARCHAR(100)     NOT NULL,
    Qty_CNT         INT               NOT NULL,
    Unit_AMT        DECIMAL(18,2)     NOT NULL,
    Line_AMT        DECIMAL(18,2)     NOT NULL,
    Detail_SEQ      INT               NOT NULL,      -- _SEQ: Sequence
    CONSTRAINT PK_OrderDetail PRIMARY KEY (Detail_ID),
    CONSTRAINT FK_OrderDetail_Order FOREIGN KEY (Order_ID) REFERENCES TB_Order(Order_ID)
);

GO

-- ============================================
-- 2. STORED PROCEDURES (USP_ Prefix)
-- Naming Pattern: USP_Entity_Action
-- ============================================

-- --------------------------------------------
-- 2.1 USP_User_Get: 사용자 단건 조회
-- --------------------------------------------
CREATE OR ALTER PROCEDURE USP_User_Get
    @User_ID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- SMA: 결과는 클라이언트에서 자동 바인딩됨
    -- 컬럼명의 접미어(_NM, _DT, _AMT 등)가 UI 렌더링 힌트로 작용
    SELECT 
        User_ID,
        User_NM,
        Email_NM,
        Balance_AMT,
        Point_CNT,
        Birth_DT,
        Reg_DT,
        Is_Active,
        Is_Premium
    FROM TB_User
    WHERE User_ID = @User_ID
      AND Del_YN = 'N';
END
GO

-- --------------------------------------------
-- 2.2 USP_User_List: 사용자 목록 조회
-- --------------------------------------------
CREATE OR ALTER PROCEDURE USP_User_List
    @Search_NM      NVARCHAR(50) = NULL,
    @Is_Active      BIT = NULL,
    @Page_CNT       INT = 1,
    @PageSize_CNT   INT = 20
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @Offset INT = (@Page_CNT - 1) * @PageSize_CNT;
    
    -- 전체 건수 (페이징용)
    SELECT COUNT(*) AS Total_CNT
    FROM TB_User
    WHERE Del_YN = 'N'
      AND (@Search_NM IS NULL OR User_NM LIKE '%' + @Search_NM + '%')
      AND (@Is_Active IS NULL OR Is_Active = @Is_Active);
    
    -- 데이터 목록
    SELECT 
        User_ID,
        User_NM,
        Email_NM,
        Balance_AMT,
        Reg_DT,
        Is_Active,
        Is_Premium
    FROM TB_User
    WHERE Del_YN = 'N'
      AND (@Search_NM IS NULL OR User_NM LIKE '%' + @Search_NM + '%')
      AND (@Is_Active IS NULL OR Is_Active = @Is_Active)
    ORDER BY Reg_DT DESC
    OFFSET @Offset ROWS
    FETCH NEXT @PageSize_CNT ROWS ONLY;
END
GO

-- --------------------------------------------
-- 2.3 USP_User_Create: 사용자 생성
-- --------------------------------------------
CREATE OR ALTER PROCEDURE USP_User_Create
    @User_NM        NVARCHAR(50),
    @Email_NM       NVARCHAR(100),
    @Birth_DT       DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
    BEGIN TRY
        -- ========================================
        -- VALIDATION (Exception Sovereignty)
        -- 모든 비즈니스 규칙은 DB에서 검증
        -- ========================================
        
        -- 이름 필수 체크
        IF @User_NM IS NULL OR LEN(TRIM(@User_NM)) = 0
        BEGIN
            THROW 51001, N'사용자 이름은 필수입니다.', 1;
        END
        
        -- 이메일 필수 체크
        IF @Email_NM IS NULL OR LEN(TRIM(@Email_NM)) = 0
        BEGIN
            THROW 51002, N'이메일 주소는 필수입니다.', 1;
        END
        
        -- 이메일 중복 체크
        IF EXISTS (SELECT 1 FROM TB_User WHERE Email_NM = @Email_NM AND Del_YN = 'N')
        BEGIN
            THROW 51003, N'이미 등록된 이메일 주소입니다.', 1;
        END
        
        -- 이메일 형식 체크 (간단한 패턴)
        IF @Email_NM NOT LIKE '%_@__%.__%'
        BEGIN
            THROW 51004, N'올바른 이메일 형식이 아닙니다.', 1;
        END
        
        -- ========================================
        -- INSERT
        -- ========================================
        INSERT INTO TB_User (User_NM, Email_NM, Birth_DT)
        VALUES (TRIM(@User_NM), TRIM(@Email_NM), @Birth_DT);
        
        DECLARE @New_ID INT = SCOPE_IDENTITY();
        
        -- 성공 결과 반환
        SELECT 
            'SUCCESS' AS Result_CD,
            N'사용자가 성공적으로 등록되었습니다.' AS Result_Msg,
            @New_ID AS User_ID;
            
    END TRY
    BEGIN CATCH
        -- Exception Sovereignty: 에러 메시지 그대로 전달
        THROW;
    END CATCH
END
GO

-- --------------------------------------------
-- 2.4 USP_User_Update: 사용자 수정
-- --------------------------------------------
CREATE OR ALTER PROCEDURE USP_User_Update
    @User_ID        INT,
    @User_NM        NVARCHAR(50),
    @Email_NM       NVARCHAR(100),
    @Birth_DT       DATE = NULL,
    @Is_Active      BIT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
    BEGIN TRY
        -- 존재 여부 체크
        IF NOT EXISTS (SELECT 1 FROM TB_User WHERE User_ID = @User_ID AND Del_YN = 'N')
        BEGIN
            THROW 51010, N'존재하지 않는 사용자입니다.', 1;
        END
        
        -- 이메일 중복 체크 (자기 자신 제외)
        IF EXISTS (SELECT 1 FROM TB_User WHERE Email_NM = @Email_NM AND User_ID != @User_ID AND Del_YN = 'N')
        BEGIN
            THROW 51003, N'이미 등록된 이메일 주소입니다.', 1;
        END
        
        -- UPDATE
        UPDATE TB_User
        SET User_NM = COALESCE(TRIM(@User_NM), User_NM),
            Email_NM = COALESCE(TRIM(@Email_NM), Email_NM),
            Birth_DT = COALESCE(@Birth_DT, Birth_DT),
            Is_Active = COALESCE(@Is_Active, Is_Active),
            Mod_DT = GETDATE()
        WHERE User_ID = @User_ID;
        
        SELECT 
            'SUCCESS' AS Result_CD,
            N'사용자 정보가 수정되었습니다.' AS Result_Msg;
            
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

-- --------------------------------------------
-- 2.5 USP_User_Delete: 사용자 삭제 (Soft Delete)
-- --------------------------------------------
CREATE OR ALTER PROCEDURE USP_User_Delete
    @User_ID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    IF NOT EXISTS (SELECT 1 FROM TB_User WHERE User_ID = @User_ID AND Del_YN = 'N')
    BEGIN
        THROW 51010, N'존재하지 않는 사용자입니다.', 1;
    END
    
    -- Soft Delete
    UPDATE TB_User
    SET Del_YN = 'Y',
        Mod_DT = GETDATE()
    WHERE User_ID = @User_ID;
    
    SELECT 
        'SUCCESS' AS Result_CD,
        N'사용자가 삭제되었습니다.' AS Result_Msg;
END
GO

-- --------------------------------------------
-- 2.6 USP_Payment_Process: 결제 처리
-- Exception Sovereignty 예제
-- --------------------------------------------
CREATE OR ALTER PROCEDURE USP_Payment_Process
    @User_ID    INT,
    @Amount_AMT DECIMAL(18,2)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION
        
        DECLARE @Balance DECIMAL(18,2);
        DECLARE @User_NM NVARCHAR(50);
        
        -- 사용자 정보 조회 (WITH LOCK)
        SELECT @Balance = Balance_AMT, @User_NM = User_NM
        FROM TB_User WITH (UPDLOCK)
        WHERE User_ID = @User_ID AND Del_YN = 'N';
        
        IF @User_NM IS NULL
        BEGIN
            THROW 51010, N'존재하지 않는 사용자입니다.', 1;
        END
        
        -- ========================================
        -- Exception Sovereignty 핵심 예제
        -- 구체적이고 실용적인 에러 메시지
        -- ========================================
        IF @Balance < @Amount_AMT
        BEGIN
            DECLARE @Shortage DECIMAL(18,2) = @Amount_AMT - @Balance;
            DECLARE @ErrorMsg NVARCHAR(500) = 
                N'잔액이 ' + FORMAT(@Shortage, 'N0') + N'원 부족합니다. ' +
                N'현재 잔액: ' + FORMAT(@Balance, 'N0') + N'원, ' +
                N'결제 금액: ' + FORMAT(@Amount_AMT, 'N0') + N'원';
            
            THROW 51100, @ErrorMsg, 1;
        END
        
        -- 잔액 차감
        UPDATE TB_User
        SET Balance_AMT = Balance_AMT - @Amount_AMT,
            Mod_DT = GETDATE()
        WHERE User_ID = @User_ID;
        
        COMMIT TRANSACTION
        
        -- 성공 결과
        SELECT 
            'SUCCESS' AS Result_CD,
            N'결제가 완료되었습니다.' AS Result_Msg,
            @Balance - @Amount_AMT AS New_Balance_AMT;
            
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

-- --------------------------------------------
-- 2.7 USP_Order_Create: 주문 생성
-- 복잡한 트랜잭션 예제
-- --------------------------------------------
CREATE OR ALTER PROCEDURE USP_Order_Create
    @User_ID        INT,
    @Ship_Addr_DESC NVARCHAR(500),
    @Items          NVARCHAR(MAX)  -- JSON Array: [{"Product_NM":"...", "Qty_CNT":1, "Unit_AMT":1000}, ...]
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION
        
        -- 사용자 존재 확인
        IF NOT EXISTS (SELECT 1 FROM TB_User WHERE User_ID = @User_ID AND Del_YN = 'N')
        BEGIN
            THROW 51010, N'존재하지 않는 사용자입니다.', 1;
        END
        
        -- 아이템 검증
        IF @Items IS NULL OR LEN(@Items) = 0
        BEGIN
            THROW 51200, N'주문 상품이 없습니다.', 1;
        END
        
        -- 총액 계산
        DECLARE @Total_AMT DECIMAL(18,2);
        SELECT @Total_AMT = SUM(CAST(JSON_VALUE(value, '$.Qty_CNT') AS INT) * 
                                CAST(JSON_VALUE(value, '$.Unit_AMT') AS DECIMAL(18,2)))
        FROM OPENJSON(@Items);
        
        -- 주문 헤더 생성
        INSERT INTO TB_Order (User_ID, Total_AMT, Ship_Addr_DESC)
        VALUES (@User_ID, @Total_AMT, @Ship_Addr_DESC);
        
        DECLARE @Order_ID INT = SCOPE_IDENTITY();
        
        -- 주문 상세 생성
        INSERT INTO TB_OrderDetail (Order_ID, Product_NM, Qty_CNT, Unit_AMT, Line_AMT, Detail_SEQ)
        SELECT 
            @Order_ID,
            JSON_VALUE(value, '$.Product_NM'),
            CAST(JSON_VALUE(value, '$.Qty_CNT') AS INT),
            CAST(JSON_VALUE(value, '$.Unit_AMT') AS DECIMAL(18,2)),
            CAST(JSON_VALUE(value, '$.Qty_CNT') AS INT) * CAST(JSON_VALUE(value, '$.Unit_AMT') AS DECIMAL(18,2)),
            ROW_NUMBER() OVER (ORDER BY (SELECT NULL))
        FROM OPENJSON(@Items);
        
        COMMIT TRANSACTION
        
        SELECT 
            'SUCCESS' AS Result_CD,
            N'주문이 완료되었습니다.' AS Result_Msg,
            @Order_ID AS Order_ID,
            @Total_AMT AS Total_AMT;
            
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

-- ============================================
-- 3. USER DEFINED FUNCTIONS (UFN_ Prefix)
-- ============================================

-- 나이 계산 함수
CREATE OR ALTER FUNCTION UFN_GetAge (@Birth_DT DATE)
RETURNS INT
AS
BEGIN
    IF @Birth_DT IS NULL RETURN NULL;
    
    RETURN DATEDIFF(YEAR, @Birth_DT, GETDATE()) - 
           CASE WHEN DATEADD(YEAR, DATEDIFF(YEAR, @Birth_DT, GETDATE()), @Birth_DT) > GETDATE()
                THEN 1 ELSE 0 END;
END
GO

-- 금액 포맷팅 함수
CREATE OR ALTER FUNCTION UFN_FormatAmount (@Amount DECIMAL(18,2))
RETURNS NVARCHAR(50)
AS
BEGIN
    RETURN FORMAT(@Amount, 'N0') + N'원';
END
GO

-- ============================================
-- 4. VIEWS (VW_ Prefix)
-- ============================================

CREATE OR ALTER VIEW VW_UserSummary
AS
SELECT 
    u.User_ID,
    u.User_NM,
    u.Email_NM,
    u.Balance_AMT,
    dbo.UFN_FormatAmount(u.Balance_AMT) AS Balance_Display,
    dbo.UFN_GetAge(u.Birth_DT) AS Age_CNT,
    u.Reg_DT,
    u.Is_Active,
    u.Is_Premium,
    (SELECT COUNT(*) FROM TB_Order o WHERE o.User_ID = u.User_ID AND o.Del_YN = 'N') AS Order_CNT,
    (SELECT ISNULL(SUM(o.Total_AMT), 0) FROM TB_Order o WHERE o.User_ID = u.User_ID AND o.Del_YN = 'N') AS TotalOrder_AMT
FROM TB_User u
WHERE u.Del_YN = 'N';
GO

-- ============================================
-- 5. SAMPLE DATA
-- ============================================

-- 테스트 사용자 데이터
INSERT INTO TB_User (User_NM, Email_NM, Balance_AMT, Point_CNT, Birth_DT, Is_Premium)
VALUES 
    (N'홍길동', 'hong@example.com', 1500000, 1000, '1990-03-15', 1),
    (N'김철수', 'kim@example.com', 250000, 500, '1985-07-22', 0),
    (N'이영희', 'lee@example.com', 3200000, 2500, '1992-11-08', 1),
    (N'박민수', 'park@example.com', 50000, 100, '1988-01-30', 0),
    (N'정수진', 'jung@example.com', 800000, 750, '1995-05-12', 0);
GO

-- ============================================
-- END OF SCRIPT
-- ============================================
PRINT N'SMA Database Schema created successfully!';
PRINT N'Tables: TB_User, TB_Order, TB_OrderDetail';
PRINT N'Procedures: USP_User_*, USP_Payment_Process, USP_Order_Create';
PRINT N'Functions: UFN_GetAge, UFN_FormatAmount';
PRINT N'Views: VW_UserSummary';
GO
