import React, { useState } from 'react';

// Updated interface
interface ContainerStat {
  id: string;
  name: string;
  cpu: string;
  memory: string;
  status: 'RUNNING' | 'STOPPED' | 'PENDING';
  cpuUsagePercent: number; // Added for the bar graph
}

// Updated mock data reflecting desired services
const mockContainerData: ContainerStat[] = [
  {
    id: 'task-app',
    name: 'prod-e-app',
    cpu: '0.25 vCPU',
    memory: '512 MiB',
    status: 'RUNNING',
    cpuUsagePercent: 75, // Example usage
  },
  {
    id: 'task-backend',
    name: 'prod-e-backend',
    cpu: '0.25 vCPU',
    memory: '512 MiB',
    status: 'RUNNING',
    cpuUsagePercent: 65,
  },
  {
    id: 'task-grafana',
    name: 'prod-e-grafana',
    cpu: '0.15 vCPU',
    memory: '300 MiB',
    status: 'RUNNING',
    cpuUsagePercent: 45,
  },
  {
    id: 'task-prometheus',
    name: 'prod-e-prometheus',
    cpu: '0.10 vCPU',
    memory: '256 MiB',
    status: 'RUNNING',
    cpuUsagePercent: 30,
  },
];

// Helper function to render the bar
const renderUsageBar = (percentage: number, barWidth = 20) => {
  const filledBlocks = Math.round((percentage / 100) * barWidth);
  const emptyBlocks = barWidth - filledBlocks;
  // Use a bright color for filled, dimmer for empty - adjust colors as needed
  return (
    <span className="font-mono text-xs">
      <span className="text-[#7aa2f7]">{'█'.repeat(filledBlocks)}</span>
      <span className="text-[#414868]">{'░'.repeat(emptyBlocks)}</span>
      <span className="ml-2 text-gray-400">{`${percentage}%`}</span>
    </span>
  );
};

const ResourceMonitorPanel: React.FC = () => {
  const [containers] = useState<ContainerStat[]>(mockContainerData);

  // Comment out unused handler for now
  /*
  const handleRefresh = () => {
    // Placeholder for refresh logic
    console.log('Refresh clicked');
  };
  */

  const getStatusColor = (status: ContainerStat['status']) => {
    switch (status) {
      case 'RUNNING':
        return 'text-[#9ece6a]'; // Green
      case 'STOPPED':
        return 'text-red-500'; // Restore original Red
      case 'PENDING':
        return 'text-yellow-500'; // Yellow
      default:
        return 'text-gray-400';
    }
  };

  return (
    <div className="h-full flex flex-col" style={{ padding: '1rem' }}>
      {/* Header: Use flex-grow on title span to push button right */}
      <h2 className="text-lg font-semibold text-[#7aa2f7] mb-4 flex items-center">
        <span className="flex-grow" style={{ textShadow: '0 0 8px rgba(122, 162, 247, 0.4)' }}>
          prod-e-cluster
        </span>
        {/* Refresh indicator: Smaller text, adjusted padding */}
        <span
          className="text-[10px] text-gray-400 font-mono font-normal
                     border border-[#e0af68] rounded-full px-1 py-1"
          // Add onClick handler here later if needed, maybe cursor-pointer
        >
          (R)efresh
        </span>
      </h2>
      <div className="flex-grow overflow-y-auto pr-2 space-y-3">
        {' '}
        {/* Increased spacing slightly */}
        {containers.length > 0 ? (
          containers.map(container => (
            <div key={container.id} className="text-sm">
              <div className="flex justify-between items-baseline mb-0.5">
                <span className="text-[#c0caf5]">{container.name}</span>
                <span className={`text-xs font-semibold ${getStatusColor(container.status)}`}>
                  {container.status}
                </span>
              </div>
              <div className="text-xs text-gray-400 flex justify-between mb-1">
                <span>CPU: {container.cpu}</span>
                <span>MEM: {container.memory}</span>
              </div>
              {/* Added Usage Bar */}
              <div className="text-xs">{renderUsageBar(container.cpuUsagePercent)}</div>
            </div>
          ))
        ) : (
          <p className="text-sm text-gray-400">No container data available.</p>
        )}
      </div>
    </div>
  );
};

export default ResourceMonitorPanel;
