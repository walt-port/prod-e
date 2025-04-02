import React from 'react';
import AnimatedLogo from '../components/AnimatedLogo';
import InfoBox from '../components/InfoBox';
import ResourceMonitorPanel from '../components/ResourceMonitorPanel';

const Dashboard: React.FC = () => {
  return (
    <div className="flex flex-col h-full p-4">
      {/* Header - Restore font-family if needed, assuming Hermit might not be globally available yet */}
      <h1 className="text-3xl font-bold text-center text-[#bb9af7] mb-6">
        Prod-E Monitoring Dashboard
      </h1>

      {/* Restore exact structure - Use inline style for padding around the grid */}
      <div className="flex-grow" style={{ padding: '1rem' }}>
        {/* Use inline style for the gap between grid items */}
        <div className="grid grid-cols-2 grid-rows-2 h-full w-full" style={{ gap: '1rem' }}>
          {/* Panel 1: Use ResourceMonitorPanel (handles its own padding) */}
          <div className="border border-[#7aa2f7] rounded-lg overflow-hidden shadow-lg bg-[#1a1b26]">
            <ResourceMonitorPanel />
          </div>

          {/* Panel 2: Restore Original Placeholder Text Color */}
          <div className="border border-[#9ece6a] rounded-lg overflow-hidden shadow-lg bg-[#1a1b26]">
            <div className="h-full flex items-center justify-center text-gray-500">
              Infrastructure Diagram Panel (Placeholder)
            </div>
          </div>

          {/* Panel 3: Info Box Panel */}
          <div className="border border-[#e0af68] rounded-lg overflow-hidden shadow-lg bg-[#1a1b26]">
            <InfoBox />
          </div>

          {/* Panel 4: Restore Original Wrapper Styles */}
          <div className="border border-[#bb9af7] rounded-lg overflow-hidden shadow-lg bg-[#1a1b26] flex items-center justify-center">
            {/* Component instance */}
            <AnimatedLogo />
          </div>
        </div>
      </div>
    </div>
  );
};

export default Dashboard;
