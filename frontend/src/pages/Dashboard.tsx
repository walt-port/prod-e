import React from 'react';
import AnimatedLogo from '../components/AnimatedLogo';
import InfoBox from '../components/InfoBox';
import InfrastructureDiagram from '../components/InfrastructureDiagram';
import ResourceMonitorPanel from '../components/ResourceMonitorPanel';

const Dashboard: React.FC = () => {
  return (
    <div className="flex flex-col h-screen p-4 border border-[#bb9af7] rounded-xl bg-[#1a1b26]">
      {/* Header - Restore font-family if needed, assuming Hermit might not be globally available yet */}
      <h1 className="text-3xl font-bold text-center text-[#bb9af7] mb-6">
        Prod-E Monitoring Dashboard
      </h1>

      {/* flex-grow allows this div to take remaining vertical space */}
      <div className="flex-grow overflow-hidden">
        {/* Grid: Removed h-full */}
        <div className="grid grid-cols-2 h-full w-full" style={{ gap: '1rem' }}>
          {/* Panel 1: Add overflow-y-auto */}
          <div className="border border-[#7aa2f7] rounded-lg overflow-y-auto shadow-lg bg-[#1f2335]">
            <ResourceMonitorPanel />
          </div>

          {/* Panel 2: Add overflow-y-auto */}
          <div className="border border-[#9ece6a] rounded-lg overflow-y-auto shadow-lg bg-[#1f2335]">
            <InfrastructureDiagram />
            {/* <div>Diagram Placeholder</div> */}
          </div>

          {/* Panel 3: Ensure overflow-y-auto is present */}
          <div className="border border-[#e0af68] rounded-lg overflow-y-auto shadow-lg bg-[#1f2335]">
            <InfoBox />
          </div>

          {/* Panel 4: Add overflow-y-auto */}
          <div className="border border-[#bb9af7] rounded-lg overflow-y-auto shadow-lg bg-[#1f2335] flex items-center justify-center">
            <AnimatedLogo />
          </div>
        </div>
      </div>
    </div>
  );
};

export default Dashboard;
