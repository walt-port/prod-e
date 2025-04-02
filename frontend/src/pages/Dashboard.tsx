import React from 'react';
import AnimatedLogo from '../components/AnimatedLogo';
import InfoBox from '../components/InfoBox';
import InfrastructureDiagram from '../components/InfrastructureDiagram';
import ResourceMonitorPanel from '../components/ResourceMonitorPanel';

const Dashboard: React.FC = () => {
  return (
    <div
      className="flex flex-col h-screen p-4 border border-[#bb9af7] bg-[#1a1b26]"
      style={{ borderRadius: '0.75rem' }}
    >
      {/* Header - Restore font-family if needed, assuming Hermit might not be globally available yet */}
      <h1 className="text-3xl font-bold text-center text-[#bb9af7] mb-6">
        Prod-E Monitoring Dashboard
      </h1>

      {/* flex-grow allows this div to take remaining vertical space - Added overflow-hidden and padding */}
      <div className="flex-grow overflow-hidden" style={{ padding: '1rem' }}>
        {/* Grid - Restore h-full to fill flex parent */}
        <div className="grid grid-cols-2 h-full w-full" style={{ gap: '1rem' }}>
          {/* Panel 1: Add overflow-y-auto */}
          <div
            className="border border-[#7aa2f7] overflow-y-auto shadow-lg bg-[#1f2335]"
            style={{
              borderRadius: '0.5rem',
              boxShadow: '0 0 12px rgba(122, 162, 247, 0.4)',
            }}
          >
            <ResourceMonitorPanel />
          </div>

          {/* Panel 2: Add overflow-y-auto */}
          <div
            className="border border-[#9ece6a] overflow-y-auto shadow-lg bg-[#1f2335]"
            style={{
              borderRadius: '0.5rem',
              boxShadow: '0 0 12px rgba(158, 206, 106, 0.4)',
            }}
          >
            <InfrastructureDiagram />
            {/* <div>Diagram Placeholder</div> */}
          </div>

          {/* Panel 3: Ensure overflow-y-auto is present */}
          <div
            className="border border-[#e0af68] overflow-y-auto shadow-lg bg-[#1f2335]"
            style={{
              borderRadius: '0.5rem',
              boxShadow: '0 0 12px rgba(224, 175, 104, 0.4)',
            }}
          >
            <InfoBox />
          </div>

          {/* Panel 4: Add overflow-y-auto */}
          <div
            className="border border-[#bb9af7] overflow-y-auto shadow-lg bg-[#1f2335] flex items-center justify-center"
            style={{
              borderRadius: '0.5rem',
              boxShadow: '0 0 12px rgba(187, 154, 247, 0.4)',
            }}
          >
            <AnimatedLogo />
          </div>
        </div>
      </div>
    </div>
  );
};

export default Dashboard;
