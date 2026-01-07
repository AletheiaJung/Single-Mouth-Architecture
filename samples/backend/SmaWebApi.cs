// ============================================
// Single-Mouth Architecture (SMA)
// Backend Layer - C# WebAPI Reference Implementation
// ============================================
// Author: Aletheia Jung
// Version: 1.0.0
// Framework: .NET 8.0
// ============================================

// ============================================
// 1. Program.cs - Entry Point
// ============================================

using Microsoft.Data.SqlClient;
using System.Data;
using System.Text.Json;

var builder = WebApplication.CreateBuilder(args);

// Services
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// SMA Database Service (Singleton)
builder.Services.AddSingleton<ISmaDatabase>(sp => 
    new SmaDatabase(builder.Configuration.GetConnectionString("DefaultConnection")!));

// CORS for React Frontend
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseCors("AllowAll");
app.UseAuthorization();
app.MapControllers();

app.Run();

// ============================================
// 2. ISmaDatabase.cs - Database Interface
// ============================================

/// <summary>
/// SMA Database Interface
/// Zero-Logic: 오직 SP 실행만 담당
/// </summary>
public interface ISmaDatabase
{
    /// <summary>
    /// SP 실행 후 Self-Describing Packet 반환
    /// </summary>
    Task<SmaResult> ExecuteAsync(string spName, object? parameters = null);
    
    /// <summary>
    /// SP 실행 후 다중 결과셋 반환
    /// </summary>
    Task<SmaMultiResult> ExecuteMultiAsync(string spName, object? parameters = null);
}

// ============================================
// 3. SmaDatabase.cs - Database Implementation
// ============================================

/// <summary>
/// SMA Database 구현체
/// 핵심: SP 결과를 메타데이터와 함께 반환 (Self-Describing Packet)
/// </summary>
public class SmaDatabase : ISmaDatabase
{
    private readonly string _connectionString;

    public SmaDatabase(string connectionString)
    {
        _connectionString = connectionString;
    }

    public async Task<SmaResult> ExecuteAsync(string spName, object? parameters = null)
    {
        using var connection = new SqlConnection(_connectionString);
        using var command = new SqlCommand(spName, connection)
        {
            CommandType = CommandType.StoredProcedure
        };

        // 파라미터 자동 바인딩
        if (parameters != null)
        {
            AddParameters(command, parameters);
        }

        await connection.OpenAsync();
        
        using var reader = await command.ExecuteReaderAsync();
        return await BuildSmaResultAsync(reader);
    }

    public async Task<SmaMultiResult> ExecuteMultiAsync(string spName, object? parameters = null)
    {
        using var connection = new SqlConnection(_connectionString);
        using var command = new SqlCommand(spName, connection)
        {
            CommandType = CommandType.StoredProcedure
        };

        if (parameters != null)
        {
            AddParameters(command, parameters);
        }

        await connection.OpenAsync();
        
        using var reader = await command.ExecuteReaderAsync();
        var results = new List<SmaResult>();
        
        do
        {
            results.Add(await BuildSmaResultAsync(reader));
        } while (await reader.NextResultAsync());

        return new SmaMultiResult { Results = results };
    }

    /// <summary>
    /// Self-Describing Packet 생성
    /// 메타데이터 + 데이터를 함께 반환
    /// </summary>
    private async Task<SmaResult> BuildSmaResultAsync(SqlDataReader reader)
    {
        var result = new SmaResult();
        
        // 메타데이터 추출 (컬럼명, 타입, 제약조건)
        var schemaTable = reader.GetSchemaTable();
        if (schemaTable != null)
        {
            foreach (DataRow row in schemaTable.Rows)
            {
                var columnName = row["ColumnName"].ToString()!;
                var dataType = ((Type)row["DataType"]).Name;
                var maxLength = row["ColumnSize"] != DBNull.Value ? (int)row["ColumnSize"] : (int?)null;
                var isNullable = row["AllowDBNull"] != DBNull.Value && (bool)row["AllowDBNull"];

                result.Meta.Columns.Add(columnName);
                result.Meta.Types.Add(MapToSmaType(dataType, columnName));
                
                // SMA Semantic Naming에서 추가 메타 추출
                result.Meta.Constraints[columnName] = new SmaConstraint
                {
                    MaxLength = maxLength,
                    Required = !isNullable,
                    Format = GetFormatFromColumnName(columnName)
                };
            }
        }

        // 데이터 추출
        while (await reader.ReadAsync())
        {
            var row = new List<object?>();
            for (int i = 0; i < reader.FieldCount; i++)
            {
                var value = reader.IsDBNull(i) ? null : reader.GetValue(i);
                row.Add(value);
            }
            result.Data.Add(row);
        }

        return result;
    }

    /// <summary>
    /// SMA Semantic Naming 기반 타입 매핑
    /// </summary>
    private string MapToSmaType(string dotNetType, string columnName)
    {
        // Semantic Naming Protocol 적용
        if (columnName.EndsWith("_DT")) return "date";
        if (columnName.EndsWith("_AMT")) return "currency";
        if (columnName.EndsWith("_CNT")) return "integer";
        if (columnName.EndsWith("_Rate")) return "percentage";
        if (columnName.StartsWith("Is_") || columnName.StartsWith("Has_")) return "boolean";
        
        // 기본 타입 매핑
        return dotNetType switch
        {
            "Int32" or "Int64" => "integer",
            "Decimal" or "Double" => "number",
            "DateTime" => "datetime",
            "Boolean" => "boolean",
            _ => "string"
        };
    }

    /// <summary>
    /// SMA Semantic Naming 기반 포맷 힌트
    /// </summary>
    private string? GetFormatFromColumnName(string columnName)
    {
        if (columnName.EndsWith("_DT")) return "YYYY-MM-DD";
        if (columnName.EndsWith("_AMT")) return "#,##0";
        if (columnName.EndsWith("_Rate")) return "0.00%";
        if (columnName.EndsWith("_YN")) return "Y/N";
        return null;
    }

    private void AddParameters(SqlCommand command, object parameters)
    {
        var properties = parameters.GetType().GetProperties();
        foreach (var prop in properties)
        {
            var value = prop.GetValue(parameters);
            command.Parameters.AddWithValue($"@{prop.Name}", value ?? DBNull.Value);
        }
    }
}

// ============================================
// 4. SmaResult.cs - Self-Describing Packet
// ============================================

/// <summary>
/// SMA Self-Describing Packet
/// 메타데이터와 데이터를 함께 포함하여 프론트엔드가 자동 렌더링 가능
/// </summary>
public class SmaResult
{
    public SmaMeta Meta { get; set; } = new();
    public List<List<object?>> Data { get; set; } = new();
    
    /// <summary>
    /// 단일 행을 Dictionary로 변환 (편의 메서드)
    /// </summary>
    public Dictionary<string, object?>? FirstRow()
    {
        if (Data.Count == 0) return null;
        
        var dict = new Dictionary<string, object?>();
        for (int i = 0; i < Meta.Columns.Count; i++)
        {
            dict[Meta.Columns[i]] = Data[0][i];
        }
        return dict;
    }
}

public class SmaMeta
{
    public List<string> Columns { get; set; } = new();
    public List<string> Types { get; set; } = new();
    public Dictionary<string, SmaConstraint> Constraints { get; set; } = new();
}

public class SmaConstraint
{
    public int? MaxLength { get; set; }
    public bool Required { get; set; }
    public string? Format { get; set; }
}

public class SmaMultiResult
{
    public List<SmaResult> Results { get; set; } = new();
}

// ============================================
// 5. SmaController.cs - API Controller (Zero-Logic)
// ============================================

using Microsoft.AspNetCore.Mvc;

/// <summary>
/// SMA Controller Base
/// Zero-Logic: 비즈니스 로직 없음, 오직 SP 호출만
/// </summary>
[ApiController]
[Route("api/[controller]")]
public class UsersController : ControllerBase
{
    private readonly ISmaDatabase _db;

    public UsersController(ISmaDatabase db)
    {
        _db = db;
    }

    /// <summary>
    /// 사용자 단건 조회
    /// Zero-Logic: SP 호출 → 결과 반환
    /// </summary>
    [HttpGet("{id}")]
    public async Task<IActionResult> Get(int id)
    {
        try
        {
            var result = await _db.ExecuteAsync("USP_User_Get", new { User_ID = id });
            
            if (result.Data.Count == 0)
                return NotFound(new { message = "사용자를 찾을 수 없습니다." });
            
            return Ok(result);
        }
        catch (SqlException ex)
        {
            // Exception Sovereignty: DB 에러 메시지 그대로 전달
            return BadRequest(new { message = ex.Message, code = ex.Number });
        }
    }

    /// <summary>
    /// 사용자 목록 조회 (페이징)
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> List(
        [FromQuery] string? search = null,
        [FromQuery] bool? isActive = null,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        try
        {
            var result = await _db.ExecuteMultiAsync("USP_User_List", new
            {
                Search_NM = search,
                Is_Active = isActive,
                Page_CNT = page,
                PageSize_CNT = pageSize
            });

            return Ok(new
            {
                total = result.Results[0].Data[0][0], // Total_CNT
                meta = result.Results[1].Meta,
                data = result.Results[1].Data
            });
        }
        catch (SqlException ex)
        {
            return BadRequest(new { message = ex.Message, code = ex.Number });
        }
    }

    /// <summary>
    /// 사용자 생성
    /// Zero-Logic: 검증은 DB(SP)에서 수행
    /// </summary>
    [HttpPost]
    public async Task<IActionResult> Create([FromBody] JsonElement body)
    {
        try
        {
            var result = await _db.ExecuteAsync("USP_User_Create", new
            {
                User_NM = body.GetProperty("User_NM").GetString(),
                Email_NM = body.GetProperty("Email_NM").GetString(),
                Birth_DT = body.TryGetProperty("Birth_DT", out var dt) ? dt.GetString() : null
            });

            var row = result.FirstRow();
            return Ok(row);
        }
        catch (SqlException ex)
        {
            // Exception Sovereignty: DB 에러 그대로 전달
            return BadRequest(new { message = ex.Message, code = ex.Number });
        }
    }

    /// <summary>
    /// 사용자 수정
    /// </summary>
    [HttpPut("{id}")]
    public async Task<IActionResult> Update(int id, [FromBody] JsonElement body)
    {
        try
        {
            var result = await _db.ExecuteAsync("USP_User_Update", new
            {
                User_ID = id,
                User_NM = body.TryGetProperty("User_NM", out var nm) ? nm.GetString() : null,
                Email_NM = body.TryGetProperty("Email_NM", out var em) ? em.GetString() : null,
                Birth_DT = body.TryGetProperty("Birth_DT", out var dt) ? dt.GetString() : null,
                Is_Active = body.TryGetProperty("Is_Active", out var ia) ? ia.GetBoolean() : (bool?)null
            });

            return Ok(result.FirstRow());
        }
        catch (SqlException ex)
        {
            return BadRequest(new { message = ex.Message, code = ex.Number });
        }
    }

    /// <summary>
    /// 사용자 삭제
    /// </summary>
    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id)
    {
        try
        {
            var result = await _db.ExecuteAsync("USP_User_Delete", new { User_ID = id });
            return Ok(result.FirstRow());
        }
        catch (SqlException ex)
        {
            return BadRequest(new { message = ex.Message, code = ex.Number });
        }
    }
}

/// <summary>
/// 결제 Controller
/// Exception Sovereignty 데모
/// </summary>
[ApiController]
[Route("api/[controller]")]
public class PaymentsController : ControllerBase
{
    private readonly ISmaDatabase _db;

    public PaymentsController(ISmaDatabase db)
    {
        _db = db;
    }

    /// <summary>
    /// 결제 처리
    /// DB에서 발생한 구체적인 에러 메시지가 그대로 전달됨
    /// </summary>
    [HttpPost]
    public async Task<IActionResult> Process([FromBody] JsonElement body)
    {
        try
        {
            var result = await _db.ExecuteAsync("USP_Payment_Process", new
            {
                User_ID = body.GetProperty("User_ID").GetInt32(),
                Amount_AMT = body.GetProperty("Amount_AMT").GetDecimal()
            });

            return Ok(result.FirstRow());
        }
        catch (SqlException ex)
        {
            // Exception Sovereignty: "잔액이 500원 부족합니다. 현재 잔액: 1,500원"
            // DB에서 생성한 메시지가 그대로 클라이언트에 전달됨
            return BadRequest(new { message = ex.Message, code = ex.Number });
        }
    }
}

/// <summary>
/// 주문 Controller
/// </summary>
[ApiController]
[Route("api/[controller]")]
public class OrdersController : ControllerBase
{
    private readonly ISmaDatabase _db;

    public OrdersController(ISmaDatabase db)
    {
        _db = db;
    }

    /// <summary>
    /// 주문 생성
    /// </summary>
    [HttpPost]
    public async Task<IActionResult> Create([FromBody] JsonElement body)
    {
        try
        {
            var items = body.GetProperty("Items").GetRawText();
            
            var result = await _db.ExecuteAsync("USP_Order_Create", new
            {
                User_ID = body.GetProperty("User_ID").GetInt32(),
                Ship_Addr_DESC = body.GetProperty("Ship_Addr_DESC").GetString(),
                Items = items
            });

            return Ok(result.FirstRow());
        }
        catch (SqlException ex)
        {
            return BadRequest(new { message = ex.Message, code = ex.Number });
        }
    }
}

// ============================================
// 6. appsettings.json
// ============================================
/*
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=localhost;Database=SMA_Demo;Trusted_Connection=True;TrustServerCertificate=True;"
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*"
}
*/

// ============================================
// 7. SMA.csproj
// ============================================
/*
<Project Sdk="Microsoft.NET.Sdk.Web">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="Microsoft.Data.SqlClient" Version="5.1.2" />
    <PackageReference Include="Swashbuckle.AspNetCore" Version="6.5.0" />
  </ItemGroup>
</Project>
*/
