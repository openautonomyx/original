# 📊 Self-Serve Usage & Billing Dashboard

**Customer-facing portal for usage, costs, and resource management**

---

## 🏗️ Self-Serve Architecture

```
┌──────────────────────────────────────────────────────┐
│     Customer Self-Serve Dashboard (Web + Mobile)     │
├──────────────────────────────────────────────────────┤
│                                                      │
│  Usage Dashboard        Billing & Costs             │
│  ├─ API calls          ├─ Current bill             │
│  ├─ Storage used       ├─ Cost breakdown           │
│  ├─ Users/seats        ├─ Payment history          │
│  ├─ Approvals          ├─ Invoices                 │
│  └─ Error rate         └─ Cost forecast            │
│                                                      │
│  Resources & Scaling    Alerts & Notifications     │
│  ├─ Add/remove users   ├─ Usage alerts             │
│  ├─ Upgrade plan       ├─ Cost alerts              │
│  ├─ Configure limits   ├─ Performance alerts       │
│  └─ View quotas        └─ Billing alerts           │
│                                                      │
│  Analytics & Reports    API & Integration          │
│  ├─ Usage trends       ├─ API keys                 │
│  ├─ Cost trends        ├─ Webhooks                 │
│  ├─ Performance        ├─ Usage API                │
│  └─ Export reports     └─ Billing API              │
│                                                      │
└──────────────────────────────────────────────────────┘
             ↓
┌──────────────────────────────────────────────────────┐
│  Billing Engine (Stripe / PaddleHQ)                 │
├──────────────────────────────────────────────────────┤
│ • Meter usage metrics                              │
│ • Calculate costs                                  │
│ • Generate invoices                                │
│ • Process payments                                 │
│ • Send receipts                                    │
└──────────────────────────────────────────────────────┘
             ↓
┌──────────────────────────────────────────────────────┐
│  Usage Tracking (ClickHouse)                        │
├──────────────────────────────────────────────────────┤
│ • API calls (per endpoint)                         │
│ • Storage (per tenant)                             │
│ • Users (active/invited)                           │
│ • Approvals (per month)                            │
│ • Data transfer                                    │
└──────────────────────────────────────────────────────┘
```

---

## 💰 Pricing Model

### Plans & Pricing

```yaml
Starter:
  Price: $99/month
  Users: 5
  API Calls: 100K/month
  Storage: 10GB
  Approvals: Unlimited
  Support: Email
  
Professional:
  Price: $299/month
  Users: 25
  API Calls: 1M/month
  Storage: 100GB
  Approvals: Unlimited
  Support: Priority email + chat
  
Enterprise:
  Price: Custom
  Users: Unlimited
  API Calls: Unlimited
  Storage: Unlimited
  Approvals: Unlimited
  Support: Dedicated account manager
```

### Usage Metering

```
Base Plan Price (fixed)
  ├─ Additional users: $20/user/month
  ├─ Additional storage: $0.10/GB/month
  ├─ API calls overage: $0.001/1K calls (over limit)
  └─ Data transfer: $0.05/GB

Total Bill = Base Plan + Overages
```

---

## 📈 Usage Dashboard Components

### 1. Real-Time Metrics Card

```tsx
// src/dashboard/components/UsageCard.tsx

interface UsageMetric {
  label: string
  current: number
  limit: number
  unit: string
  percentUsed: number
  trend: 'up' | 'down' | 'flat'
  lastUpdated: Date
}

export function UsageCard({ metric }: { metric: UsageMetric }) {
  return (
    <Card className="p-4">
      <div className="flex justify-between items-center mb-2">
        <span className="text-sm font-medium">{metric.label}</span>
        <Trend direction={metric.trend} />
      </div>

      {/* Progress bar */}
      <div className="mb-2">
        <ProgressBar 
          value={metric.percentUsed} 
          color={getColorFromPercent(metric.percentUsed)}
        />
      </div>

      {/* Numbers */}
      <div className="flex justify-between text-sm">
        <span>
          <strong>{formatNumber(metric.current)}</strong>
          {metric.unit}
        </span>
        <span className="text-gray-500">
          of {formatNumber(metric.limit)}{metric.unit}
        </span>
      </div>

      {/* Last updated */}
      <p className="text-xs text-gray-400 mt-2">
        Updated {formatTime(metric.lastUpdated)}
      </p>

      {/* Alert if near limit */}
      {metric.percentUsed > 80 && (
        <Alert variant="warning">
          You're using {metric.percentUsed}% of your limit
        </Alert>
      )}
    </Card>
  )
}
```

### 2. Billing Dashboard

```tsx
// src/dashboard/pages/Billing.tsx

export function BillingPage() {
  const [billing, setBilling] = useState<BillingInfo>(null)
  const [invoices, setInvoices] = useState<Invoice[]>([])

  useEffect(() => {
    fetch('/api/v1/billing/current', {
      headers: { 'Authorization': `Bearer ${getToken()}` }
    })
    .then(r => r.json())
    .then(setBilling)
  }, [])

  return (
    <div className="space-y-6">
      {/* Current Bill */}
      <Card className="p-6 bg-gradient-to-r from-blue-50 to-indigo-50">
        <div className="flex justify-between items-center">
          <div>
            <p className="text-gray-600">Current Bill (This Month)</p>
            <h2 className="text-3xl font-bold">
              ${billing?.currentAmount?.toFixed(2)}
            </h2>
          </div>
          <div className="text-right">
            <p className="text-gray-600">Due Date</p>
            <p className="text-lg font-semibold">
              {formatDate(billing?.dueDate)}
            </p>
          </div>
        </div>
      </Card>

      {/* Cost Breakdown */}
      <Card className="p-6">
        <h3 className="text-lg font-semibold mb-4">Cost Breakdown</h3>
        <div className="space-y-2">
          <CostRow label="Base Plan" amount={billing?.basePlan} />
          <CostRow label="Additional Users" amount={billing?.overages?.users} />
          <CostRow label="Storage Overage" amount={billing?.overages?.storage} />
          <CostRow label="API Call Overage" amount={billing?.overages?.apiCalls} />
          <CostRow label="Data Transfer" amount={billing?.overages?.dataTransfer} />
          <Divider />
          <CostRow 
            label="Total" 
            amount={billing?.currentAmount}
            bold
          />
        </div>
      </Card>

      {/* Invoice History */}
      <Card className="p-6">
        <h3 className="text-lg font-semibold mb-4">Invoice History</h3>
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Date</TableHead>
              <TableHead>Amount</TableHead>
              <TableHead>Status</TableHead>
              <TableHead>Action</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {invoices.map(invoice => (
              <TableRow key={invoice.id}>
                <TableCell>{formatDate(invoice.date)}</TableCell>
                <TableCell>${invoice.amount.toFixed(2)}</TableCell>
                <TableCell>
                  <Badge variant={invoice.status}>
                    {invoice.status}
                  </Badge>
                </TableCell>
                <TableCell>
                  <Button 
                    size="sm"
                    onClick={() => downloadInvoice(invoice.id)}
                  >
                    Download PDF
                  </Button>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </Card>

      {/* Payment Method */}
      <Card className="p-6">
        <h3 className="text-lg font-semibold mb-4">Payment Method</h3>
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <CreditCardIcon />
            <div>
              <p className="font-medium">•••• •••• •••• {billing?.card?.last4}</p>
              <p className="text-sm text-gray-500">
                Expires {billing?.card?.expMonth}/{billing?.card?.expYear}
              </p>
            </div>
          </div>
          <Button variant="outline">Update Payment</Button>
        </div>
      </Card>

      {/* Cost Forecast */}
      <Card className="p-6">
        <h3 className="text-lg font-semibold mb-4">Cost Forecast</h3>
        <LineChart
          data={billing?.forecast}
          xAxis="date"
          yAxis="estimatedCost"
          title="Projected Monthly Cost"
        />
      </Card>
    </div>
  )
}
```

### 3. Usage Analytics

```tsx
// src/dashboard/pages/Analytics.tsx

export function AnalyticsPage() {
  const [timeRange, setTimeRange] = useState('30d')
  const [analytics, setAnalytics] = useState(null)

  useEffect(() => {
    fetch(`/api/v1/analytics?range=${timeRange}`, {
      headers: { 'Authorization': `Bearer ${getToken()}` }
    })
    .then(r => r.json())
    .then(setAnalytics)
  }, [timeRange])

  return (
    <div className="space-y-6">
      {/* Time range selector */}
      <div className="flex gap-2">
        {['7d', '30d', '90d', 'custom'].map(range => (
          <Button
            key={range}
            variant={timeRange === range ? 'primary' : 'outline'}
            onClick={() => setTimeRange(range)}
          >
            {range === '7d' ? '7 Days' : 
             range === '30d' ? '30 Days' :
             range === '90d' ? '90 Days' :
             'Custom'}
          </Button>
        ))}
      </div>

      {/* Key metrics */}
      <div className="grid grid-cols-4 gap-4">
        <MetricCard
          label="Total API Calls"
          value={analytics?.totalApiCalls}
          change={analytics?.apiCallsChange}
        />
        <MetricCard
          label="Avg Response Time"
          value={`${analytics?.avgLatency}ms`}
          change={analytics?.latencyChange}
        />
        <MetricCard
          label="Error Rate"
          value={`${analytics?.errorRate}%`}
          change={analytics?.errorRateChange}
          color="danger"
        />
        <MetricCard
          label="Active Users"
          value={analytics?.activeUsers}
          change={analytics?.activeUsersChange}
        />
      </div>

      {/* Trends */}
      <Card className="p-6">
        <h3 className="text-lg font-semibold mb-4">API Call Trends</h3>
        <LineChart
          data={analytics?.apiCallsTrend}
          xAxis="date"
          yAxis="calls"
          label="API Calls"
        />
      </Card>

      {/* Top endpoints */}
      <Card className="p-6">
        <h3 className="text-lg font-semibold mb-4">Top Endpoints</h3>
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Endpoint</TableHead>
              <TableHead>Calls</TableHead>
              <TableHead>Avg Latency</TableHead>
              <TableHead>Error Rate</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {analytics?.topEndpoints.map(endpoint => (
              <TableRow key={endpoint.path}>
                <TableCell className="font-mono">{endpoint.path}</TableCell>
                <TableCell>{formatNumber(endpoint.calls)}</TableCell>
                <TableCell>{endpoint.avgLatency}ms</TableCell>
                <TableCell>
                  <Badge 
                    color={endpoint.errorRate > 1 ? 'danger' : 'success'}
                  >
                    {endpoint.errorRate}%
                  </Badge>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </Card>

      {/* Export */}
      <div className="flex gap-2">
        <Button onClick={() => exportToCSV('analytics')}>
          Export as CSV
        </Button>
        <Button onClick={() => exportToJSON('analytics')}>
          Export as JSON
        </Button>
      </div>
    </div>
  )
}
```

### 4. Resource Management

```tsx
// src/dashboard/pages/Resources.tsx

export function ResourcesPage() {
  const [subscription, setSubscription] = useState(null)
  const [users, setUsers] = useState([])
  const [scaling, setScaling] = useState(null)

  return (
    <div className="space-y-6">
      {/* Current Plan */}
      <Card className="p-6">
        <h3 className="text-lg font-semibold mb-4">Current Plan</h3>
        <div className="grid grid-cols-3 gap-4">
          <PlanFeature 
            label="Users Included" 
            value={subscription?.usersIncluded}
            used={subscription?.usersUsed}
          />
          <PlanFeature 
            label="Storage" 
            value={`${subscription?.storage}GB`}
            used={`${subscription?.storageUsed}GB`}
          />
          <PlanFeature 
            label="API Calls/month" 
            value={`${formatNumber(subscription?.apiCallLimit)}`}
            used={`${formatNumber(subscription?.apiCallsUsed)}`}
          />
        </div>
        
        <div className="mt-4 flex gap-2">
          <Button variant="primary">Upgrade Plan</Button>
          <Button variant="outline">Downgrade Plan</Button>
        </div>
      </Card>

      {/* User Management */}
      <Card className="p-6">
        <div className="flex justify-between items-center mb-4">
          <h3 className="text-lg font-semibold">Team Members</h3>
          <Button onClick={() => showInviteModal()}>Add User</Button>
        </div>

        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Name</TableHead>
              <TableHead>Email</TableHead>
              <TableHead>Role</TableHead>
              <TableHead>Joined</TableHead>
              <TableHead>Action</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {users.map(user => (
              <TableRow key={user.id}>
                <TableCell>{user.name}</TableCell>
                <TableCell>{user.email}</TableCell>
                <TableCell>
                  <Select value={user.role}>
                    <Option value="admin">Admin</Option>
                    <Option value="editor">Editor</Option>
                    <Option value="viewer">Viewer</Option>
                  </Select>
                </TableCell>
                <TableCell>{formatDate(user.joinedAt)}</TableCell>
                <TableCell>
                  <Button 
                    size="sm" 
                    variant="danger"
                    onClick={() => removeUser(user.id)}
                  >
                    Remove
                  </Button>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>

        {users.length >= subscription?.usersIncluded && (
          <Alert variant="warning">
            You've used all included seats. 
            <Button size="sm" onClick={() => showUpgradeModal()}>
              Add more users
            </Button>
          </Alert>
        )}
      </Card>

      {/* Auto-scaling Configuration */}
      <Card className="p-6">
        <h3 className="text-lg font-semibold mb-4">Auto-Scaling Settings</h3>
        
        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium mb-2">
              Max API Calls/month
            </label>
            <input 
              type="number" 
              className="w-full border rounded px-3 py-2"
              value={scaling?.maxApiCalls}
              onChange={(e) => updateScaling('maxApiCalls', e.target.value)}
            />
            <p className="text-xs text-gray-500 mt-1">
              Leave blank for unlimited. Each 1M calls = $10
            </p>
          </div>

          <div>
            <label className="block text-sm font-medium mb-2">
              Max Storage (GB)
            </label>
            <input 
              type="number" 
              className="w-full border rounded px-3 py-2"
              value={scaling?.maxStorage}
              onChange={(e) => updateScaling('maxStorage', e.target.value)}
            />
            <p className="text-xs text-gray-500 mt-1">
              Each additional GB = $0.10/month
            </p>
          </div>

          <div className="flex items-center gap-2">
            <input 
              type="checkbox"
              id="auto-scale"
              checked={scaling?.autoScale}
              onChange={(e) => updateScaling('autoScale', e.target.checked)}
            />
            <label htmlFor="auto-scale" className="text-sm">
              Automatically scale when limits are reached
            </label>
          </div>

          <Button onClick={() => saveScalingSettings()}>
            Save Settings
          </Button>
        </div>
      </Card>
    </div>
  )
}
```

### 5. Alerts & Notifications

```tsx
// src/dashboard/pages/Alerts.tsx

export function AlertsPage() {
  const [alerts, setAlerts] = useState([])

  return (
    <div className="space-y-6">
      <Card className="p-6">
        <h3 className="text-lg font-semibold mb-4">Alert Settings</h3>

        <div className="space-y-4">
          {/* Usage alerts */}
          <AlertSetting
            label="API Calls Limit"
            description="Alert when reaching 80% of API call limit"
            enabled={true}
            onToggle={() => {}}
            channels={['email', 'slack']}
          />

          {/* Cost alerts */}
          <AlertSetting
            label="Monthly Cost"
            description="Alert when bill exceeds $X"
            enabled={true}
            onToggle={() => {}}
            channels={['email']}
            value={500}
          />

          {/* Performance alerts */}
          <AlertSetting
            label="Error Rate"
            description="Alert when error rate exceeds 1%"
            enabled={true}
            onToggle={() => {}}
            channels={['email', 'slack', 'webhook']}
          />

          {/* Storage alerts */}
          <AlertSetting
            label="Storage Limit"
            description="Alert when reaching 90% of storage limit"
            enabled={false}
            onToggle={() => {}}
            channels={['email']}
          />
        </div>
      </Card>

      {/* Alert History */}
      <Card className="p-6">
        <h3 className="text-lg font-semibold mb-4">Alert History</h3>
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Type</TableHead>
              <TableHead>Message</TableHead>
              <TableHead>Time</TableHead>
              <TableHead>Status</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {alerts.map(alert => (
              <TableRow key={alert.id}>
                <TableCell>
                  <Badge>{alert.type}</Badge>
                </TableCell>
                <TableCell>{alert.message}</TableCell>
                <TableCell>{formatTime(alert.timestamp)}</TableCell>
                <TableCell>
                  <Badge 
                    color={alert.acknowledged ? 'gray' : 'yellow'}
                  >
                    {alert.acknowledged ? 'Acknowledged' : 'Active'}
                  </Badge>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </Card>
    </div>
  )
}
```

---

## 🔌 Backend API Endpoints

```go
// src/api/usage_handlers.go

// GET /api/v1/usage/current
func GetCurrentUsage(w http.ResponseWriter, r *http.Request) {
	tenantID := getTenantFromContext(r)
	
	usage := map[string]interface{}{
		"api_calls": map[string]interface{}{
			"current": 45230,
			"limit": 100000,
			"unit": "calls",
		},
		"storage": map[string]interface{}{
			"current": 7.3,
			"limit": 10,
			"unit": "GB",
		},
		"users": map[string]interface{}{
			"current": 4,
			"limit": 5,
			"unit": "seats",
		},
		"approvals": map[string]interface{}{
			"current": 324,
			"limit": 0, // unlimited
			"unit": "approvals",
		},
	}
	
	respondJSON(w, http.StatusOK, usage)
}

// GET /api/v1/billing/current
func GetCurrentBilling(w http.ResponseWriter, r *http.Request) {
	tenantID := getTenantFromContext(r)
	
	billing := map[string]interface{}{
		"current_amount": 299.00,
		"base_plan": 299.00,
		"overages": map[string]float64{
			"users": 40.00,
			"storage": 0.00,
			"api_calls": 0.00,
		},
		"due_date": "2026-07-25",
		"plan": "professional",
	}
	
	respondJSON(w, http.StatusOK, billing)
}

// GET /api/v1/analytics?range=30d
func GetAnalytics(w http.ResponseWriter, r *http.Request) {
	timeRange := r.URL.Query().Get("range")
	tenantID := getTenantFromContext(r)
	
	// Query ClickHouse for analytics
	analytics := map[string]interface{}{
		"total_api_calls": 1234567,
		"avg_latency": 45,
		"error_rate": 0.02,
		"active_users": 3,
	}
	
	respondJSON(w, http.StatusOK, analytics)
}

// POST /api/v1/resources/users/invite
func InviteUser(w http.ResponseWriter, r *http.Request) {
	var req struct {
		Email string `json:"email"`
		Role  string `json:"role"`
	}
	parseJSON(r.Body, &req)
	
	// Send invitation email
	// Add to pending users table
	
	respondJSON(w, http.StatusOK, map[string]string{
		"status": "invited",
	})
}

// PUT /api/v1/resources/users/{id}
func UpdateUserRole(w http.ResponseWriter, r *http.Request) {
	userID := mux.Vars(r)["id"]
	var req struct {
		Role string `json:"role"`
	}
	parseJSON(r.Body, &req)
	
	// Update user role
	
	respondJSON(w, http.StatusOK, map[string]string{
		"status": "updated",
	})
}

// DELETE /api/v1/resources/users/{id}
func RemoveUser(w http.ResponseWriter, r *http.Request) {
	userID := mux.Vars(r)["id"]
	tenantID := getTenantFromContext(r)
	
	// Remove user from tenant
	
	respondJSON(w, http.StatusOK, map[string]string{
		"status": "removed",
	})
}

// PUT /api/v1/resources/scaling
func UpdateScaling(w http.ResponseWriter, r *http.Request) {
	tenantID := getTenantFromContext(r)
	var req struct {
		MaxApiCalls  *int  `json:"max_api_calls"`
		MaxStorage   *int  `json:"max_storage"`
		AutoScale    *bool `json:"auto_scale"`
	}
	parseJSON(r.Body, &req)
	
	// Update scaling settings
	// Store in tenant_settings table
	
	respondJSON(w, http.StatusOK, map[string]string{
		"status": "updated",
	})
}

// GET /api/v1/billing/invoices
func GetInvoices(w http.ResponseWriter, r *http.Request) {
	tenantID := getTenantFromContext(r)
	
	invoices := []map[string]interface{}{
		{
			"id": "inv_123",
			"date": "2026-06-25",
			"amount": 299.00,
			"status": "paid",
		},
	}
	
	respondJSON(w, http.StatusOK, invoices)
}

// GET /api/v1/billing/invoices/{id}/pdf
func DownloadInvoice(w http.ResponseWriter, r *http.Request) {
	invoiceID := mux.Vars(r)["id"]
	tenantID := getTenantFromContext(r)
	
	// Generate PDF from invoice data
	// Stream to client
	
	w.Header().Set("Content-Type", "application/pdf")
	w.Header().Set("Content-Disposition", fmt.Sprintf("attachment; filename=invoice-%s.pdf", invoiceID))
}
```

---

## 📊 Database Schema

```sql
-- Tenant usage tracking
CREATE TABLE tenant_usage_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    date DATE NOT NULL,
    
    -- Metrics
    api_calls_total INT DEFAULT 0,
    api_calls_by_endpoint JSONB,
    storage_used_gb DECIMAL(10,2) DEFAULT 0,
    active_users INT DEFAULT 0,
    approvals_total INT DEFAULT 0,
    errors_total INT DEFAULT 0,
    
    -- Performance
    avg_latency_ms DECIMAL(10,2) DEFAULT 0,
    p95_latency_ms DECIMAL(10,2) DEFAULT 0,
    p99_latency_ms DECIMAL(10,2) DEFAULT 0,
    error_rate DECIMAL(5,2) DEFAULT 0,
    
    created_at TIMESTAMP DEFAULT NOW(),
    
    UNIQUE(tenant_id, date),
    INDEX idx_tenant_date (tenant_id, date DESC)
);

-- Billing records
CREATE TABLE tenant_billing (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    billing_month DATE NOT NULL,
    
    -- Base plan
    plan_name VARCHAR NOT NULL,
    base_price DECIMAL(10,2) NOT NULL,
    
    -- Overages
    additional_users INT DEFAULT 0,
    additional_users_cost DECIMAL(10,2) DEFAULT 0,
    storage_overage_gb DECIMAL(10,2) DEFAULT 0,
    storage_overage_cost DECIMAL(10,2) DEFAULT 0,
    api_call_overage INT DEFAULT 0,
    api_call_overage_cost DECIMAL(10,2) DEFAULT 0,
    data_transfer_gb DECIMAL(10,2) DEFAULT 0,
    data_transfer_cost DECIMAL(10,2) DEFAULT 0,
    
    -- Total
    total_cost DECIMAL(10,2) NOT NULL,
    status VARCHAR DEFAULT 'pending', -- pending, paid, overdue
    
    created_at TIMESTAMP DEFAULT NOW(),
    paid_at TIMESTAMP,
    
    UNIQUE(tenant_id, billing_month)
);

-- Invoices
CREATE TABLE invoices (
    id VARCHAR PRIMARY KEY,
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    billing_id UUID NOT NULL REFERENCES tenant_billing(id),
    
    invoice_date DATE NOT NULL,
    due_date DATE NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    status VARCHAR DEFAULT 'unpaid',
    
    pdf_url VARCHAR,
    payment_method VARCHAR,
    
    created_at TIMESTAMP DEFAULT NOW(),
    paid_at TIMESTAMP,
    
    INDEX idx_tenant (tenant_id),
    INDEX idx_status (status)
);

-- Usage alerts
CREATE TABLE usage_alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    
    alert_type VARCHAR NOT NULL, -- 'api_calls', 'storage', 'cost', 'error_rate'
    threshold DECIMAL(10,2) NOT NULL,
    current_value DECIMAL(10,2),
    
    enabled BOOLEAN DEFAULT TRUE,
    notification_channels JSONB, -- ['email', 'slack', 'webhook']
    
    last_triggered TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    
    INDEX idx_tenant_type (tenant_id, alert_type)
);

-- Scaling settings
CREATE TABLE scaling_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) UNIQUE,
    
    max_api_calls_per_month INT,
    max_storage_gb INT,
    auto_scale BOOLEAN DEFAULT FALSE,
    
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
```

---

## ✅ Self-Serve Usage Features

- [x] Real-time usage metrics
- [x] Billing dashboard
- [x] Invoice history & download
- [x] Cost breakdown & forecasting
- [x] User management (add/remove/roles)
- [x] Plan upgrade/downgrade
- [x] Auto-scaling configuration
- [x] Usage alerts & notifications
- [x] Analytics & trends
- [x] Export reports (CSV, JSON)
- [x] API keys management
- [x] Webhook configuration
- [x] Payment method management
- [x] Usage history (30/90 day views)
- [x] Performance metrics
- [x] Per-endpoint analytics

---

**Status:** ✅ READY FOR IMPLEMENTATION  
**Type:** Customer-facing portal  
**Access:** Self-serve dashboard  
**Billing:** Integrated with Stripe/PaddleHQ  
**Analytics:** Powered by ClickHouse
