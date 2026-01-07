// ============================================
// Single-Mouth Architecture (SMA)
// Frontend Layer - React Reference Implementation
// ============================================
// Author: Aletheia Jung
// Version: 1.0.0
// Framework: React 18 + TypeScript (minimal)
// ============================================

// ============================================
// 1. smaClient.ts - API Client
// ============================================

const API_BASE = 'http://localhost:5000/api';

/**
 * SMA Result 타입 (Self-Describing Packet)
 * TypeScript 최소 사용: 오직 API 응답 구조만 정의
 */
interface SmaMeta {
  columns: string[];
  types: string[];
  constraints: Record<string, {
    maxLength?: number;
    required: boolean;
    format?: string;
  }>;
}

interface SmaResult {
  meta: SmaMeta;
  data: any[][];
}

interface SmaListResult {
  total: number;
  meta: SmaMeta;
  data: any[][];
}

/**
 * SMA API Client
 * Zero-Logic: 데이터 가공 없이 전달만
 */
export const smaClient = {
  async get(endpoint: string): Promise<SmaResult> {
    const res = await fetch(`${API_BASE}${endpoint}`);
    if (!res.ok) {
      const error = await res.json();
      throw new Error(error.message);
    }
    return res.json();
  },

  async list(endpoint: string): Promise<SmaListResult> {
    const res = await fetch(`${API_BASE}${endpoint}`);
    if (!res.ok) {
      const error = await res.json();
      throw new Error(error.message);
    }
    return res.json();
  },

  async post(endpoint: string, data: any): Promise<any> {
    const res = await fetch(`${API_BASE}${endpoint}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data)
    });
    if (!res.ok) {
      const error = await res.json();
      throw new Error(error.message);
    }
    return res.json();
  },

  async put(endpoint: string, data: any): Promise<any> {
    const res = await fetch(`${API_BASE}${endpoint}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data)
    });
    if (!res.ok) {
      const error = await res.json();
      throw new Error(error.message);
    }
    return res.json();
  },

  async delete(endpoint: string): Promise<any> {
    const res = await fetch(`${API_BASE}${endpoint}`, { method: 'DELETE' });
    if (!res.ok) {
      const error = await res.json();
      throw new Error(error.message);
    }
    return res.json();
  }
};

// ============================================
// 2. useSmartQuery.ts - SMA Data Hook
// ============================================

import { useState, useEffect } from 'react';

/**
 * SMA Smart Query Hook
 * Self-Describing Packet을 받아 자동으로 데이터 구조 파악
 */
export function useSmartQuery(endpoint: string) {
  const [data, setData] = useState<any>(null);
  const [meta, setMeta] = useState<SmaMeta | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchData = async () => {
      try {
        setLoading(true);
        const result = await smaClient.get(endpoint);
        
        // Self-Describing: 메타와 데이터 분리
        setMeta(result.meta);
        
        // 첫 번째 행을 객체로 변환
        if (result.data.length > 0) {
          const row: Record<string, any> = {};
          result.meta.columns.forEach((col, i) => {
            row[col] = result.data[0][i];
          });
          setData(row);
        }
      } catch (err: any) {
        setError(err.message);
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, [endpoint]);

  return { data, meta, loading, error, refetch: () => {} };
}

/**
 * SMA Smart List Hook
 * 목록 데이터용 (페이징 포함)
 */
export function useSmartList(endpoint: string) {
  const [data, setData] = useState<any[]>([]);
  const [meta, setMeta] = useState<SmaMeta | null>(null);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchData = async () => {
    try {
      setLoading(true);
      const result = await smaClient.list(endpoint);
      
      setMeta(result.meta);
      setTotal(result.total);
      
      // 배열 데이터를 객체 배열로 변환
      const rows = result.data.map(row => {
        const obj: Record<string, any> = {};
        result.meta.columns.forEach((col, i) => {
          obj[col] = row[i];
        });
        return obj;
      });
      setData(rows);
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, [endpoint]);

  return { data, meta, total, loading, error, refetch: fetchData };
}

// ============================================
// 3. AutoForm.tsx - SMA Auto-Binding Form
// ============================================

import React from 'react';

interface AutoFormProps {
  data: Record<string, any>;
  meta: SmaMeta;
  onSubmit: (data: Record<string, any>) => void;
  readOnly?: boolean;
}

/**
 * SMA AutoForm
 * 메타데이터 기반 자동 폼 생성
 * 컬럼명의 접미어로 입력 타입 자동 결정
 */
export function AutoForm({ data, meta, onSubmit, readOnly = false }: AutoFormProps) {
  const [formData, setFormData] = React.useState(data);

  const handleChange = (column: string, value: any) => {
    setFormData(prev => ({ ...prev, [column]: value }));
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onSubmit(formData);
  };

  return (
    <form onSubmit={handleSubmit} className="sma-form">
      {meta.columns.map((column, index) => {
        // _ID 컬럼은 읽기 전용
        if (column.endsWith('_ID')) {
          return (
            <div key={column} className="form-group">
              <label>{formatLabel(column)}</label>
              <input type="text" value={formData[column] || ''} disabled />
            </div>
          );
        }

        const type = meta.types[index];
        const constraint = meta.constraints[column];
        
        return (
          <div key={column} className="form-group">
            <label>
              {formatLabel(column)}
              {constraint?.required && <span className="required">*</span>}
            </label>
            {renderInput(column, type, formData[column], constraint, readOnly, handleChange)}
          </div>
        );
      })}
      
      {!readOnly && (
        <button type="submit" className="btn-submit">저장</button>
      )}
    </form>
  );
}

/**
 * SMA Semantic Naming 기반 입력 필드 렌더링
 */
function renderInput(
  column: string,
  type: string,
  value: any,
  constraint: any,
  readOnly: boolean,
  onChange: (col: string, val: any) => void
) {
  // Boolean: Is_, Has_ 접두어 → Checkbox
  if (column.startsWith('Is_') || column.startsWith('Has_')) {
    return (
      <input
        type="checkbox"
        checked={value || false}
        disabled={readOnly}
        onChange={e => onChange(column, e.target.checked)}
      />
    );
  }

  // Date: _DT 접미어 → DatePicker
  if (column.endsWith('_DT')) {
    const dateValue = value ? new Date(value).toISOString().split('T')[0] : '';
    return (
      <input
        type="date"
        value={dateValue}
        disabled={readOnly}
        onChange={e => onChange(column, e.target.value)}
      />
    );
  }

  // Currency: _AMT 접미어 → Number with formatting
  if (column.endsWith('_AMT')) {
    return (
      <input
        type="text"
        value={formatCurrency(value)}
        disabled={readOnly}
        className="text-right"
        onChange={e => onChange(column, parseCurrency(e.target.value))}
      />
    );
  }

  // Count: _CNT 접미어 → Integer only
  if (column.endsWith('_CNT')) {
    return (
      <input
        type="number"
        value={value || 0}
        min={0}
        step={1}
        disabled={readOnly}
        className="text-right"
        onChange={e => onChange(column, parseInt(e.target.value) || 0)}
      />
    );
  }

  // Percentage: _Rate 접미어 → Percentage input
  if (column.endsWith('_Rate')) {
    return (
      <input
        type="number"
        value={value || 0}
        min={0}
        max={100}
        step={0.01}
        disabled={readOnly}
        className="text-right"
        onChange={e => onChange(column, parseFloat(e.target.value) || 0)}
      />
    );
  }

  // Yes/No: _YN 접미어 → Select
  if (column.endsWith('_YN')) {
    return (
      <select
        value={value || 'N'}
        disabled={readOnly}
        onChange={e => onChange(column, e.target.value)}
      >
        <option value="Y">예</option>
        <option value="N">아니오</option>
      </select>
    );
  }

  // Description: _DESC 접미어 → Textarea
  if (column.endsWith('_DESC')) {
    return (
      <textarea
        value={value || ''}
        maxLength={constraint?.maxLength}
        disabled={readOnly}
        rows={3}
        onChange={e => onChange(column, e.target.value)}
      />
    );
  }

  // Default: Text input
  return (
    <input
      type="text"
      value={value || ''}
      maxLength={constraint?.maxLength}
      disabled={readOnly}
      onChange={e => onChange(column, e.target.value)}
    />
  );
}

// ============================================
// 4. AutoGrid.tsx - SMA Auto-Binding Grid
// ============================================

interface AutoGridProps {
  data: Record<string, any>[];
  meta: SmaMeta;
  onRowClick?: (row: Record<string, any>) => void;
}

/**
 * SMA AutoGrid
 * 메타데이터 기반 자동 그리드 생성
 */
export function AutoGrid({ data, meta, onRowClick }: AutoGridProps) {
  return (
    <table className="sma-grid">
      <thead>
        <tr>
          {meta.columns.map(column => (
            <th key={column} className={getHeaderClass(column)}>
              {formatLabel(column)}
            </th>
          ))}
        </tr>
      </thead>
      <tbody>
        {data.map((row, rowIndex) => (
          <tr 
            key={rowIndex} 
            onClick={() => onRowClick?.(row)}
            className={onRowClick ? 'clickable' : ''}
          >
            {meta.columns.map((column, colIndex) => (
              <td key={column} className={getCellClass(column, meta.types[colIndex])}>
                {formatCell(row[column], column, meta.types[colIndex])}
              </td>
            ))}
          </tr>
        ))}
      </tbody>
    </table>
  );
}

// ============================================
// 5. Utility Functions
// ============================================

/**
 * 컬럼명을 사람이 읽기 좋은 레이블로 변환
 * User_NM → User Name, Is_Active → Active
 */
function formatLabel(column: string): string {
  return column
    .replace(/^Is_|^Has_/, '')
    .replace(/_NM$|_DT$|_AMT$|_CNT$|_CD$|_YN$|_Rate$|_SEQ$|_DESC$|_ID$/, '')
    .replace(/_/g, ' ')
    .trim();
}

/**
 * 통화 포맷팅
 */
function formatCurrency(value: any): string {
  if (value == null) return '';
  const num = typeof value === 'number' ? value : parseFloat(value);
  return isNaN(num) ? '' : num.toLocaleString('ko-KR');
}

/**
 * 통화 문자열 파싱
 */
function parseCurrency(value: string): number {
  return parseFloat(value.replace(/,/g, '')) || 0;
}

/**
 * 셀 값 포맷팅 (Semantic Naming 기반)
 */
function formatCell(value: any, column: string, type: string): string {
  if (value == null) return '-';

  // Boolean
  if (column.startsWith('Is_') || column.startsWith('Has_')) {
    return value ? '✓' : '✗';
  }

  // Date
  if (column.endsWith('_DT')) {
    return new Date(value).toLocaleDateString('ko-KR');
  }

  // Currency
  if (column.endsWith('_AMT')) {
    return formatCurrency(value) + '원';
  }

  // Count
  if (column.endsWith('_CNT')) {
    return value.toLocaleString('ko-KR');
  }

  // Percentage
  if (column.endsWith('_Rate')) {
    return value.toFixed(2) + '%';
  }

  // Yes/No
  if (column.endsWith('_YN')) {
    return value === 'Y' ? '예' : '아니오';
  }

  return String(value);
}

/**
 * 헤더 클래스 (정렬용)
 */
function getHeaderClass(column: string): string {
  if (column.endsWith('_AMT') || column.endsWith('_CNT') || column.endsWith('_Rate')) {
    return 'text-right';
  }
  if (column.startsWith('Is_') || column.startsWith('Has_')) {
    return 'text-center';
  }
  return '';
}

/**
 * 셀 클래스 (정렬용)
 */
function getCellClass(column: string, type: string): string {
  if (column.endsWith('_AMT') || column.endsWith('_CNT') || column.endsWith('_Rate')) {
    return 'text-right';
  }
  if (column.startsWith('Is_') || column.startsWith('Has_')) {
    return 'text-center';
  }
  return '';
}

// ============================================
// 6. Example Usage - UserList.tsx
// ============================================

export function UserList() {
  const { data, meta, total, loading, error, refetch } = useSmartList('/users');
  const [selectedUser, setSelectedUser] = React.useState<any>(null);

  if (loading) return <div className="loading">로딩 중...</div>;
  if (error) return <div className="error">에러: {error}</div>;
  if (!meta) return null;

  return (
    <div className="user-list">
      <h2>사용자 목록 (총 {total}명)</h2>
      
      <AutoGrid 
        data={data} 
        meta={meta} 
        onRowClick={setSelectedUser}
      />
      
      {selectedUser && (
        <div className="modal">
          <h3>사용자 상세</h3>
          <AutoForm 
            data={selectedUser}
            meta={meta}
            onSubmit={async (updated) => {
              await smaClient.put(`/users/${updated.User_ID}`, updated);
              refetch();
              setSelectedUser(null);
            }}
          />
          <button onClick={() => setSelectedUser(null)}>닫기</button>
        </div>
      )}
    </div>
  );
}

// ============================================
// 7. Example Usage - UserProfile.tsx
// ============================================

interface UserProfileProps {
  userId: number;
}

export function UserProfile({ userId }: UserProfileProps) {
  const { data, meta, loading, error } = useSmartQuery(`/users/${userId}`);

  if (loading) return <div className="loading">로딩 중...</div>;
  if (error) return <div className="error">에러: {error}</div>;
  if (!data || !meta) return <div>사용자를 찾을 수 없습니다.</div>;

  return (
    <div className="user-profile">
      <h2>사용자 프로필</h2>
      <AutoForm 
        data={data}
        meta={meta}
        readOnly={true}
        onSubmit={() => {}}
      />
    </div>
  );
}

// ============================================
// 8. Example Usage - PaymentForm.tsx
// ============================================

export function PaymentForm({ userId }: { userId: number }) {
  const [amount, setAmount] = React.useState('');
  const [result, setResult] = React.useState<any>(null);
  const [error, setError] = React.useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setResult(null);

    try {
      const response = await smaClient.post('/payments', {
        User_ID: userId,
        Amount_AMT: parseCurrency(amount)
      });
      setResult(response);
    } catch (err: any) {
      // Exception Sovereignty: DB에서 온 메시지 그대로 표시
      // 예: "잔액이 500원 부족합니다. 현재 잔액: 1,500원"
      setError(err.message);
    }
  };

  return (
    <div className="payment-form">
      <h2>결제</h2>
      <form onSubmit={handleSubmit}>
        <div className="form-group">
          <label>결제 금액</label>
          <input
            type="text"
            value={amount}
            onChange={e => setAmount(e.target.value)}
            placeholder="금액 입력"
            className="text-right"
          />
        </div>
        <button type="submit">결제하기</button>
      </form>

      {error && (
        <div className="error-message">
          {/* DB Exception 메시지가 그대로 표시됨 */}
          {error}
        </div>
      )}

      {result && (
        <div className="success-message">
          {result.Result_Msg}<br />
          새 잔액: {formatCurrency(result.New_Balance_AMT)}원
        </div>
      )}
    </div>
  );
}

// ============================================
// 9. App.tsx - Main Application
// ============================================

export function App() {
  const [view, setView] = React.useState<'list' | 'profile' | 'payment'>('list');
  const [selectedUserId, setSelectedUserId] = React.useState<number>(1);

  return (
    <div className="app">
      <header>
        <h1>SMA Demo Application</h1>
        <nav>
          <button onClick={() => setView('list')}>사용자 목록</button>
          <button onClick={() => setView('profile')}>프로필</button>
          <button onClick={() => setView('payment')}>결제</button>
        </nav>
      </header>

      <main>
        {view === 'list' && <UserList />}
        {view === 'profile' && <UserProfile userId={selectedUserId} />}
        {view === 'payment' && <PaymentForm userId={selectedUserId} />}
      </main>

      <footer>
        <p>Single-Mouth Architecture (SMA) Demo</p>
        <p>© 2026 Aletheia Jung</p>
      </footer>
    </div>
  );
}

// ============================================
// 10. styles.css (참고용)
// ============================================
/*
.sma-form {
  max-width: 500px;
  margin: 0 auto;
}

.form-group {
  margin-bottom: 1rem;
}

.form-group label {
  display: block;
  margin-bottom: 0.5rem;
  font-weight: bold;
}

.form-group input,
.form-group select,
.form-group textarea {
  width: 100%;
  padding: 0.5rem;
  border: 1px solid #ccc;
  border-radius: 4px;
}

.text-right {
  text-align: right;
}

.text-center {
  text-align: center;
}

.required {
  color: red;
  margin-left: 4px;
}

.sma-grid {
  width: 100%;
  border-collapse: collapse;
}

.sma-grid th,
.sma-grid td {
  padding: 0.75rem;
  border: 1px solid #ddd;
}

.sma-grid th {
  background-color: #f5f5f5;
}

.sma-grid tr.clickable:hover {
  background-color: #f0f0f0;
  cursor: pointer;
}

.error-message {
  color: red;
  padding: 1rem;
  background-color: #fee;
  border-radius: 4px;
  margin-top: 1rem;
}

.success-message {
  color: green;
  padding: 1rem;
  background-color: #efe;
  border-radius: 4px;
  margin-top: 1rem;
}
*/
