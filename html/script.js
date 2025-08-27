// Global variables
let currentTab = 'vehicles';
let jobActive = false;
let selectedVehicle = null;
let playerData = {
    money: 0,
    completedDeliveries: 0,
    totalDeliveries: 0,
    stats: {
        totalBoxes: 0,
        totalEarned: 0,
        totalTime: 0,
        totalTrips: 0
    }
};

// NUI Event Handlers
window.addEventListener('message', function(event) {
    const data = event.data;
    
    switch(data.action) {
        case 'openNUI':
            openNUI(data.data);
            break;
        case 'closeNUI':
            closeNUI();
            break;
        case 'updateJobStatus':
            updateJobStatus(data.data);
            break;
        case 'updatePlayerData':
            updatePlayerData(data.data);
            break;
        case 'updateDeliveryProgress':
            updateDeliveryProgress(data.data);
            break;
        case 'showNotification':
            showNotification(data.message, data.type);
            break;
        case 'updateStats':
            updateStats(data.data);
            break;
    }
});

// ESC key handler
document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
        closeNUI();
    }
});

// Initialize NUI
function openNUI(data = {}) {
    document.getElementById('main-container').classList.remove('hidden');
    
    // Update player data if provided
    if (data.playerData) {
        updatePlayerData(data.playerData);
    }
    
    // Load vehicles if provided
    if (data.vehicles) {
        loadVehicles(data.vehicles);
    }
    
    // Update job status if provided
    if (data.jobStatus) {
        updateJobStatus(data.jobStatus);
    }
    
    // Update stats if provided
    if (data.stats) {
        updateStats(data.stats);
    }
    
    // Load settings
    loadSettings();
    
    // Set focus for NUI
    SetNuiFocus(true, true);
}

function closeNUI() {
    document.getElementById('main-container').classList.add('hidden');
    closeVehicleModal();
    
    // Send close event to Lua
    fetch(`https://${GetParentResourceName()}/closeNUI`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({})
    });
    
    SetNuiFocus(false, false);
}

// Tab Management
function showTab(tabName) {
    // Remove active class from all tabs and buttons
    document.querySelectorAll('.tab-content').forEach(tab => {
        tab.classList.remove('active');
    });
    
    document.querySelectorAll('.nav-btn').forEach(btn => {
        btn.classList.remove('active');
    });
    
    // Show selected tab and mark button as active
    document.getElementById(`${tabName}-tab`).classList.add('active');
    document.querySelector(`[data-tab="${tabName}"]`).classList.add('active');
    
    currentTab = tabName;
    
    // Load tab-specific data
    switch(tabName) {
        case 'vehicles':
            loadVehicles();
            break;
        case 'jobs':
            loadJobInfo();
            break;
        case 'stats':
            loadStatistics();
            break;
        case 'settings':
            loadSettings();
            break;
    }
}

// Vehicle Management
function loadVehicles(vehicles = null) {
    const vehiclesList = document.getElementById('vehicles-list');
    
    if (!vehicles) {
        // Request vehicles from Lua
        fetch(`https://${GetParentResourceName()}/getVehicles`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json; charset=UTF-8',
            },
            body: JSON.stringify({})
        });
        return;
    }
    
    vehiclesList.innerHTML = '';
    
    vehicles.forEach(vehicle => {
        const vehicleCard = createVehicleCard(vehicle);
        vehiclesList.appendChild(vehicleCard);
    });
}

function createVehicleCard(vehicle) {
    const card = document.createElement('div');
    card.className = 'vehicle-card';
    card.onclick = () => selectVehicle(vehicle);
    
    card.innerHTML = `
        <div class="vehicle-image">
            <i class="fas fa-truck"></i>
        </div>
        <div class="vehicle-info">
            <h3>${vehicle.name}</h3>
            <ul class="vehicle-features">
                <li><i class="fas fa-check"></i> ${vehicle.capacity || 'Medium'} Capacity</li>
                <li><i class="fas fa-check"></i> ${vehicle.efficiency || 'Good'} Fuel Efficiency</li>
                <li><i class="fas fa-check"></i> ${vehicle.durability || 'High'} Durability</li>
            </ul>
        </div>
        <div class="vehicle-price">
            <span class="price">$${vehicle.price || 500}</span>
            <button class="rent-btn" onclick="event.stopPropagation(); selectVehicle(${JSON.stringify(vehicle).replace(/"/g, '&quot;')})">
                <i class="fas fa-key"></i> Rent
            </button>
        </div>
    `;
    
    return card;
}

function selectVehicle(vehicle) {
    selectedVehicle = vehicle;
    
    // Update modal content
    document.getElementById('modal-vehicle-name').textContent = vehicle.name;
    document.getElementById('modal-rental-cost').textContent = `$${vehicle.price || 500}`;
    document.getElementById('modal-capacity').textContent = vehicle.capacity || 'Medium';
    document.getElementById('modal-efficiency').textContent = vehicle.efficiency || 'Good';
    
    // Show modal
    document.getElementById('vehicle-modal').classList.remove('hidden');
}

function confirmVehicleRental() {
    if (!selectedVehicle) return;
    
    showLoading(true);
    
    // Send rental request to Lua
    fetch(`https://${GetParentResourceName()}/rentVehicle`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({
            vehicleModel: selectedVehicle.model,
            vehicleData: selectedVehicle
        })
    }).then(() => {
        showLoading(false);
        closeVehicleModal();
        showNotification(`${selectedVehicle.name} rented successfully!`, 'success');
        
        // Switch to jobs tab
        showTab('jobs');
    }).catch(error => {
        showLoading(false);
        showNotification('Failed to rent vehicle', 'error');
        console.error('Rental error:', error);
    });
}

function closeVehicleModal() {
    document.getElementById('vehicle-modal').classList.add('hidden');
    selectedVehicle = null;
}

// Job Management
function loadJobInfo() {
    // Request current job info from Lua
    fetch(`https://${GetParentResourceName()}/getJobInfo`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({})
    });
}

function updateJobStatus(data) {
    jobActive = data.active || false;
    
    const jobInfo = document.getElementById('job-info');
    const currentDelivery = document.getElementById('current-delivery');
    
    if (jobActive && data.currentLocation) {
        // Hide no-job message
        jobInfo.style.display = 'none';
        currentDelivery.style.display = 'block';
        
        // Update delivery info
        document.getElementById('delivery-location').textContent = data.currentLocation.storeLabel || 'Unknown Location';
        document.getElementById('delivery-boxes').textContent = data.currentLocation.dropCount || 0;
        
        // Update progress
        const progress = (data.currentLocation.currentCount || 0) / (data.currentLocation.dropCount || 1) * 100;
        document.getElementById('delivery-progress').style.width = `${progress}%`;
        
        // Update counters
        document.getElementById('completed-deliveries').textContent = data.completedDeliveries || 0;
        document.getElementById('total-deliveries').textContent = data.totalDeliveries || 0;
    } else {
        // Show no-job message
        jobInfo.style.display = 'block';
        currentDelivery.style.display = 'none';
        
        // Reset counters
        document.getElementById('completed-deliveries').textContent = '0';
        document.getElementById('total-deliveries').textContent = '0';
    }
}

function updateDeliveryProgress(data) {
    if (data.currentLocation) {
        document.getElementById('delivery-location').textContent = data.currentLocation.storeLabel || 'Unknown Location';
        document.getElementById('delivery-boxes').textContent = data.currentLocation.dropCount || 0;
        
        const progress = (data.currentLocation.currentCount || 0) / (data.currentLocation.dropCount || 1) * 100;
        document.getElementById('delivery-progress').style.width = `${progress}%`;
    }
    
    if (data.completedDeliveries !== undefined) {
        document.getElementById('completed-deliveries').textContent = data.completedDeliveries;
    }
    
    if (data.totalDeliveries !== undefined) {
        document.getElementById('total-deliveries').textContent = data.totalDeliveries;
    }
}

// Player Data Management
function updatePlayerData(data) {
    playerData = { ...playerData, ...data };
    
    // Update money display
    if (data.money !== undefined) {
        document.getElementById('player-money').textContent = `$${data.money.toLocaleString()}`;
    }
    
    // Update other data as needed
    if (data.completedDeliveries !== undefined) {
        document.getElementById('completed-deliveries').textContent = data.completedDeliveries;
    }
    
    if (data.totalDeliveries !== undefined) {
        document.getElementById('total-deliveries').textContent = data.totalDeliveries;
    }
}

// Statistics Management
function loadStatistics() {
    // Request stats from Lua
    fetch(`https://${GetParentResourceName()}/getStatistics`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({})
    });
}

function updateStats(stats) {
    playerData.stats = { ...playerData.stats, ...stats };
    
    // Update stat displays
    document.getElementById('total-boxes').textContent = stats.totalBoxes || 0;
    document.getElementById('total-earned').textContent = `$${(stats.totalEarned || 0).toLocaleString()}`;
    document.getElementById('total-time').textContent = `${Math.floor((stats.totalTime || 0) / 3600)}h`;
    document.getElementById('total-trips').textContent = stats.totalTrips || 0;
    
    // Update performance chart if needed
    updatePerformanceChart(stats);
}

function updatePerformanceChart(stats) {
    // Simple implementation - you can enhance with Chart.js
    const canvas = document.getElementById('performance-chart');
    if (!canvas) return;
    
    const ctx = canvas.getContext('2d');
    canvas.width = canvas.offsetWidth;
    canvas.height = 200;
    
    // Clear canvas
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    
    // Draw simple bar chart
    const data = [
        { label: 'Boxes', value: stats.totalBoxes || 0, color: '#3498db' },
        { label: 'Trips', value: stats.totalTrips || 0, color: '#2ecc71' },
        { label: 'Hours', value: Math.floor((stats.totalTime || 0) / 3600), color: '#f39c12' }
    ];
    
    const maxValue = Math.max(...data.map(d => d.value)) || 1;
    const barWidth = canvas.width / data.length - 20;
    
    data.forEach((item, index) => {
        const x = index * (barWidth + 20) + 10;
        const height = (item.value / maxValue) * (canvas.height - 40);
        const y = canvas.height - height - 20;
        
        // Draw bar
        ctx.fillStyle = item.color;
        ctx.fillRect(x, y, barWidth, height);
        
        // Draw label
        ctx.fillStyle = '#ffffff';
        ctx.font = '12px Arial';
        ctx.textAlign = 'center';
        ctx.fillText(item.label, x + barWidth / 2, canvas.height - 5);
        ctx.fillText(item.value, x + barWidth / 2, y - 5);
    });
}

// Settings Management
function loadSettings() {
    // Load settings from localStorage or default values
    const settings = {
        gpsRoute: localStorage.getItem('trucker_gps_route') !== 'false',
        soundEffects: localStorage.getItem('trucker_sound_effects') !== 'false',
        autoAccept: localStorage.getItem('trucker_auto_accept') === 'true',
        notificationPosition: localStorage.getItem('trucker_notification_position') || 'top-right'
    };
    
    // Update UI elements
    document.getElementById('gps-route').checked = settings.gpsRoute;
    document.getElementById('sound-effects').checked = settings.soundEffects;
    document.getElementById('auto-accept').checked = settings.autoAccept;
    document.getElementById('notification-position').value = settings.notificationPosition;
    
    // Add event listeners
    document.getElementById('gps-route').onchange = () => saveSettings();
    document.getElementById('sound-effects').onchange = () => saveSettings();
    document.getElementById('auto-accept').onchange = () => saveSettings();
    document.getElementById('notification-position').onchange = () => saveSettings();
}

function saveSettings() {
    const settings = {
        gpsRoute: document.getElementById('gps-route').checked,
        soundEffects: document.getElementById('sound-effects').checked,
        autoAccept: document.getElementById('auto-accept').checked,
        notificationPosition: document.getElementById('notification-position').value
    };
    
    // Save to localStorage
    localStorage.setItem('trucker_gps_route', settings.gpsRoute);
    localStorage.setItem('trucker_sound_effects', settings.soundEffects);
    localStorage.setItem('trucker_auto_accept', settings.autoAccept);
    localStorage.setItem('trucker_notification_position', settings.notificationPosition);
    
    // Send to Lua
    fetch(`https://${GetParentResourceName()}/updateSettings`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify(settings)
    });
}

// Action Functions
function returnVehicle() {
    fetch(`https://${GetParentResourceName()}/returnVehicle`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({})
    });
    
    showNotification('Vehicle return request sent', 'info');
}

function collectPaycheck() {
    fetch(`https://${GetParentResourceName()}/collectPaycheck`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({})
    });
    
    showNotification('Paycheck collection request sent', 'info');
}

// Utility Functions
function showLoading(show) {
    const overlay = document.getElementById('loading-overlay');
    if (show) {
        overlay.classList.remove('hidden');
    } else {
        overlay.classList.add('hidden');
    }
}

function showNotification(message, type = 'info') {
    // Create notification element
    const notification = document.createElement('div');
    notification.className = `notification notification-${type}`;
    notification.innerHTML = `
        <div class="notification-content">
            <i class="fas fa-${getNotificationIcon(type)}"></i>
            <span>${message}</span>
        </div>
    `;
    
    // Add styles
    notification.style.cssText = `
        position: fixed;
        top: 20px;
        right: 20px;
        background: ${getNotificationColor(type)};
        color: white;
        padding: 12px 20px;
        border-radius: 8px;
        box-shadow: 0 4px 12px rgba(0,0,0,0.3);
        z-index: 10000;
        transform: translateX(100%);
        transition: transform 0.3s ease;
        min-width: 200px;
    `;
    
    document.body.appendChild(notification);
    
    // Animate in
    setTimeout(() => {
        notification.style.transform = 'translateX(0)';
    }, 100);
    
    // Remove after delay
    setTimeout(() => {
        notification.style.transform = 'translateX(100%)';
        setTimeout(() => {
            if (notification.parentNode) {
                notification.parentNode.removeChild(notification);
            }
        }, 300);
    }, 3000);
}

function getNotificationIcon(type) {
    switch(type) {
        case 'success': return 'check-circle';
        case 'error': return 'exclamation-circle';
        case 'warning': return 'exclamation-triangle';
        default: return 'info-circle';
    }
}

function getNotificationColor(type) {
    switch(type) {
        case 'success': return '#2ecc71';
        case 'error': return '#e74c3c';
        case 'warning': return '#f39c12';
        default: return '#3498db';
    }
}

// Fake GetParentResourceName for development
function GetParentResourceName() {
    return 'qbx_truckerjob';
}

// Fake SetNuiFocus for development
function SetNuiFocus(hasFocus, hasCursor) {
    // This would be handled by the game engine
    console.log(`SetNuiFocus: ${hasFocus}, ${hasCursor}`);
}

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', function() {
    // Set initial tab
    showTab('vehicles');
    
    // Add click handlers for modal backdrop
    document.getElementById('vehicle-modal').addEventListener('click', function(event) {
        if (event.target === this) {
            closeVehicleModal();
        }
    });
    
    console.log('Trucker Job NUI Initialized');
});