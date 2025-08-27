let currentMenuData = null;

// Listen for NUI messages
window.addEventListener('message', function(event) {
    const data = event.data;
    
    switch(data.type) {
        case 'openBusMenu':
            openBusMenu(data.data);
            break;
        case 'showRouteInfo':
            showRouteInfo(data.data);
            break;
    }
});

// Close menu with Escape key
document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
        closeBusMenu();
        closeRouteInfo();
    }
});

function openBusMenu(data) {
    currentMenuData = data;
    
    // Update status display
    document.getElementById('workStatus').textContent = data.isWorking ? 'On Duty' : 'Off Duty';
    document.getElementById('passengerCount').textContent = data.activePassengers || 0;
    document.getElementById('deliveredCount').textContent = data.totalDelivered || 0;
    
    // Generate menu options
    generateMenuOptions(data);
    
    // Show menu
    document.getElementById('busMenu').style.display = 'flex';
    
    // Add entrance animation
    setTimeout(() => {
        document.querySelector('.menu-content').style.transform = 'scale(1)';
        document.querySelector('.menu-content').style.opacity = '1';
    }, 10);
}

function generateMenuOptions(data) {
    const optionsContainer = document.getElementById('menuOptions');
    optionsContainer.innerHTML = '';
    
    if (!data.isWorking) {
        // Start Job Option
        addMenuOption(optionsContainer, {
            title: 'Start Bus Job',
            description: 'Begin your bus route and start earning money',
            icon: 'fas fa-play',
            action: 'startJob',
            type: 'primary'
        });
    } else {
        if (!data.hasRentedBus) {
            // Rent Bus Option
            addMenuOption(optionsContainer, {
                title: 'Rent Bus',
                description: `Rent a bus for $${data.rentalPrice}`,
                icon: 'fas fa-key',
                action: 'rentBus',
                type: 'primary'
            });
        } else {
            // Current Route Info
            addMenuOption(optionsContainer, {
                title: 'Current Route Info',
                description: 'View information about your current route',
                icon: 'fas fa-info-circle',
                action: 'routeInfo',
                type: ''
            });
            
            // Passenger Info
            addMenuOption(optionsContainer, {
                title: 'Passenger Information',
                description: 'Show current passenger details and destinations',
                icon: 'fas fa-users',
                action: 'passengerInfo',
                type: ''
            });
        }
        
        // Finish Job Option
        addMenuOption(optionsContainer, {
            title: 'Finish Job',
            description: 'Return bus and complete your shift',
            icon: 'fas fa-flag-checkered',
            action: 'finishJob',
            type: 'warning'
        });
        
        // Cancel Job Option
        addMenuOption(optionsContainer, {
            title: 'Cancel Job',
            description: 'Cancel current job (no refund)',
            icon: 'fas fa-times',
            action: 'cancelJob',
            type: 'danger'
        });
    }
}

function addMenuOption(container, option) {
    const optionElement = document.createElement('div');
    optionElement.className = `menu-option ${option.type}`;
    optionElement.onclick = () => handleMenuAction(option.action);
    
    optionElement.innerHTML = `
        <div class="option-icon">
            <i class="${option.icon}"></i>
        </div>
        <div class="option-content">
            <div class="option-title">${option.title}</div>
            <div class="option-description">${option.description}</div>
        </div>
    `;
    
    container.appendChild(optionElement);
    
    // Add entrance animation with delay
    setTimeout(() => {
        optionElement.style.animation = 'slideInLeft 0.3s ease-out forwards';
    }, container.children.length * 50);
}

function handleMenuAction(action) {
    // Send action to Lua
    fetch(`https://${GetParentResourceName()}/${action}`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({})
    }).then(resp => resp.json()).then(resp => {
        // Handle response if needed
    });
    
    // Close menu for most actions
    if (action !== 'routeInfo') {
        closeBusMenu();
    }
}

function closeBusMenu() {
    const menu = document.getElementById('busMenu');
    const content = document.querySelector('.menu-content');
    
    // Exit animation
    content.style.animation = 'slideOut 0.3s ease-in forwards';
    
    setTimeout(() => {
        menu.style.display = 'none';
        content.style.animation = '';
    }, 300);
    
    // Send close message to Lua
    fetch(`https://${GetParentResourceName()}/closeBusMenu`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({})
    });
}

function showRouteInfo(data) {
    const modal = document.getElementById('routeInfoModal');
    const content = document.getElementById('routeInfoContent');
    
    content.innerHTML = `
        <div class="route-info-item">
            <div class="route-info-icon">
                <i class="fas fa-route"></i>
            </div>
            <div class="route-info-text">
                <div class="route-info-label">Current Route</div>
                <div class="route-info-value">${data.route || 'No Route'}</div>
            </div>
        </div>
        
        <div class="route-info-item">
            <div class="route-info-icon">
                <i class="fas fa-users"></i>
            </div>
            <div class="route-info-text">
                <div class="route-info-label">Active Passengers</div>
                <div class="route-info-value">${data.activePassengers || 0}</div>
            </div>
        </div>
        
        <div class="route-info-item">
            <div class="route-info-icon">
                <i class="fas fa-trophy"></i>
            </div>
            <div class="route-info-text">
                <div class="route-info-label">Passengers Delivered</div>
                <div class="route-info-value">${data.delivered || 0}</div>
            </div>
        </div>
        
        <div class="route-info-item">
            <div class="route-info-icon">
                <i class="fas fa-info-circle"></i>
            </div>
            <div class="route-info-text">
                <div class="route-info-label">Next Action</div>
                <div class="route-info-value">${data.message || 'No instructions'}</div>
            </div>
        </div>
    `;
    
    modal.style.display = 'flex';
}

function closeRouteInfo() {
    const modal = document.getElementById('routeInfoModal');
    modal.style.display = 'none';
}

// Add CSS animations
const style = document.createElement('style');
style.textContent = `
    @keyframes slideInLeft {
        from {
            opacity: 0;
            transform: translateX(-20px);
        }
        to {
            opacity: 1;
            transform: translateX(0);
        }
    }
    
    @keyframes slideOut {
        from {
            opacity: 1;
            transform: translateY(0) scale(1);
        }
        to {
            opacity: 0;
            transform: translateY(-30px) scale(0.95);
        }
    }
`;
document.head.appendChild(style);

// Helper function for FiveM
function GetParentResourceName() {
    return window.location.hostname === 'nui-img' || window.location.hostname === 'cfx-nui-' + window.location.hostname.split('-')[2] 
        ? window.location.pathname.split('/')[1] 
        : 'busjob';
}