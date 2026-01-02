# ============================================
# HDUCE - TEST DATA INITIALIZATION SCRIPT
# Creates test data for all services
# ============================================

Write-Host "`n=== HDUCE TEST DATA INITIALIZATION ===" -ForegroundColor Cyan
Write-Host "Starting at: $(Get-Date)`n" -ForegroundColor Gray

# ========== 1. CREATE MEDICAL SPECIALTIES ==========
Write-Host "1. Creating Medical Specialties..." -ForegroundColor Yellow

$specialties = @(
    @{name = "Cardiology"; description = "Heart and cardiovascular system"},
    @{name = "Pediatrics"; description = "Medical care for infants, children, and adolescents"},
    @{name = "Dermatology"; description = "Skin, hair, and nail conditions"},
    @{name = "Neurology"; description = "Nervous system disorders"},
    @{name = "Orthopedics"; description = "Musculoskeletal system"},
    @{name = "Ophthalmology"; description = "Eye diseases and disorders"},
    @{name = "Psychiatry"; description = "Mental health and disorders"},
    @{name = "Dentistry"; description = "Oral health and dental care"}
)

$specialtyIds = @()
foreach ($spec in $specialties) {
    $body = $spec | ConvertTo-Json
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:8002/specialties" -Method Post -Body $body -ContentType "application/json"
        $specialtyIds += $response.id
        Write-Host "   Created: $($spec.name)" -ForegroundColor Green
    } catch {
        Write-Host "   Error creating $($spec.name): $_" -ForegroundColor Red
    }
}

# ========== 2. CREATE USERS ==========
Write-Host "`n2. Creating Users (Doctors & Patients)..." -ForegroundColor Yellow

# Doctors users
$doctorUsers = @(
    @{name = "Dr. John Smith"; email = "john.smith@hospital.com"; age = 45},
    @{name = "Dr. Sarah Johnson"; email = "sarah.johnson@hospital.com"; age = 38},
    @{name = "Dr. Michael Brown"; email = "michael.brown@hospital.com"; age = 52},
    @{name = "Dr. Emily Davis"; email = "emily.davis@hospital.com"; age = 41},
    @{name = "Dr. Robert Wilson"; email = "robert.wilson@hospital.com"; age = 47}
)

# Patient users
$patientUsers = @(
    @{name = "Alice Johnson"; email = "alice.johnson@example.com"; age = 32},
    @{name = "Bob Williams"; email = "bob.williams@example.com"; age = 45},
    @{name = "Carol Miller"; email = "carol.miller@example.com"; age = 28},
    @{name = "David Garcia"; email = "david.garcia@example.com"; age = 60},
    @{name = "Eva Martinez"; email = "eva.martinez@example.com"; age = 35},
    @{name = "Frank Anderson"; email = "frank.anderson@example.com"; age = 42},
    @{name = "Grace Taylor"; email = "grace.taylor@example.com"; age = 29},
    @{name = "Henry Thomas"; email = "henry.thomas@example.com"; age = 55}
)

$allUserIds = @()

# Create doctor users
foreach ($user in $doctorUsers) {
    $body = $user | ConvertTo-Json
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:8001/users" -Method Post -Body $body -ContentType "application/json"
        $allUserIds += @{id = $response.id; type = "doctor"; name = $user.name}
        Write-Host "   Created Doctor User: $($user.name)" -ForegroundColor Green
    } catch {
        Write-Host "   Error creating doctor user $($user.name): $_" -ForegroundColor Red
    }
}

# Create patient users
foreach ($user in $patientUsers) {
    $body = $user | ConvertTo-Json
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:8001/users" -Method Post -Body $body -ContentType "application/json"
        $allUserIds += @{id = $response.id; type = "patient"; name = $user.name}
        Write-Host "   Created Patient User: $($user.name)" -ForegroundColor Green
    } catch {
        Write-Host "   Error creating patient user $($user.name): $_" -ForegroundColor Red
    }
}

# ========== 3. CREATE DOCTORS ==========
Write-Host "`n3. Creating Doctors..." -ForegroundColor Yellow

$doctors = @()
$doctorCounter = 0
$doctorUserIds = $allUserIds | Where-Object { $_.type -eq "doctor" }

foreach ($doctorUser in $doctorUserIds) {
    $doctor = @{
        user_id = $doctorUser.id
        license_number = "MED-" + (10000 + $doctorCounter).ToString()
        specialty_id = $specialtyIds[$doctorCounter % $specialtyIds.Count]
        consultation_duration = @(30, 45, 60)[$doctorCounter % 3]
    }
    
    $body = $doctor | ConvertTo-Json
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:8002/doctors" -Method Post -Body $body -ContentType "application/json"
        $doctors += @{id = $response.id; user_id = $doctorUser.id; name = $doctorUser.name}
        Write-Host "   Created Doctor: $($doctorUser.name) - License: $($doctor.license_number)" -ForegroundColor Green
    } catch {
        Write-Host "   Error creating doctor $($doctorUser.name): $_" -ForegroundColor Red
    }
    $doctorCounter++
}

# ========== 4. CREATE APPOINTMENTS ==========
Write-Host "`n4. Creating Appointments..." -ForegroundColor Yellow

$patientUserIds = $allUserIds | Where-Object { $_.type -eq "patient" }
$appointmentReasons = @(
    "Annual checkup",
    "Follow-up consultation",
    "Vaccination",
    "Blood test results",
    "Chronic condition management",
    "Post-surgery evaluation",
    "Emergency consultation",
    "Routine dental cleaning",
    "Eye examination",
    "Skin condition evaluation"
)

$appointmentStatuses = @("scheduled", "confirmed", "completed", "cancelled")

# Create 20 random appointments
for ($i = 0; $i -lt 20; $i++) {
    $patient = $patientUserIds | Get-Random
    $doctor = $doctors | Get-Random
    $daysFromNow = Get-Random -Minimum 1 -Maximum 30
    $hour = Get-Random -Minimum 8 -Maximum 17
    $minute = @(0, 15, 30, 45) | Get-Random
    
    $appointmentDate = (Get-Date).AddDays($daysFromNow).Date.AddHours($hour).AddMinutes($minute)
    
    $appointment = @{
        patient_id = $patient.id
        doctor_id = $doctor.id
        appointment_date = $appointmentDate.ToString("yyyy-MM-ddTHH:mm:ss")
        reason = $appointmentReasons | Get-Random
        notes = "Test appointment #$($i + 1)"
        status = $appointmentStatuses | Get-Random
    }
    
    $body = $appointment | ConvertTo-Json
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:8002/appointments" -Method Post -Body $body -ContentType "application/json"
        Write-Host "   Created Appointment: $($appointment.reason) - $($appointmentDate.ToString('MM/dd HH:mm'))" -ForegroundColor Green
    } catch {
        Write-Host "   Error creating appointment: $_" -ForegroundColor Red
    }
}

# ========== 5. VERIFICATION ==========
Write-Host "`n5. Verification..." -ForegroundColor Yellow

# Count specialties
try {
    $specialtiesCount = (Invoke-RestMethod -Uri "http://localhost:8002/specialties" -Method Get).Count
    Write-Host "   Specialties: $specialtiesCount" -ForegroundColor Cyan
} catch { Write-Host "   Error counting specialties" -ForegroundColor Red }

# Count doctors
try {
    $doctorsCount = (Invoke-RestMethod -Uri "http://localhost:8002/doctors" -Method Get).Count
    Write-Host "   Doctors: $doctorsCount" -ForegroundColor Cyan
} catch { Write-Host "   Error counting doctors" -ForegroundColor Red }

# Count appointments
try {
    $appointmentsCount = (Invoke-RestMethod -Uri "http://localhost:8002/appointments" -Method Get).Count
    Write-Host "   Appointments: $appointmentsCount" -ForegroundColor Cyan
} catch { Write-Host "   Error counting appointments" -ForegroundColor Red }

# Count users
try {
    $usersCount = (Invoke-RestMethod -Uri "http://localhost:8001/users" -Method Get).Count
    Write-Host "   Total Users: $usersCount" -ForegroundColor Cyan
} catch { Write-Host "   Error counting users" -ForegroundColor Red }

# ========== 6. DATABASE CHECK ==========
Write-Host "`n6. Database Verification..." -ForegroundColor Yellow

try {
    $tables = docker exec -it hduce-postgres psql -U hduce_user -d hduce_db -c "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_name;" -t
    Write-Host "   Tables in database:" -ForegroundColor Cyan
    $tables -split "`n" | Where-Object { $_ -match '\w' } | ForEach-Object {
        Write-Host "     - $($_.Trim())" -ForegroundColor Gray
    }
} catch {
    Write-Host "   Error checking database tables" -ForegroundColor Red
}

Write-Host "`n=== INITIALIZATION COMPLETE ===" -ForegroundColor Green
Write-Host "All test data created successfully!" -ForegroundColor Green
Write-Host "`nAccess services:" -ForegroundColor White
Write-Host "  • Auth Service:      http://localhost:8000" -ForegroundColor Cyan
Write-Host "  • User Service:      http://localhost:8001" -ForegroundColor Cyan
Write-Host "  • Appointment Service: http://localhost:8002" -ForegroundColor Cyan
Write-Host "  • Adminer (DB GUI):  http://localhost:8080" -ForegroundColor Cyan
