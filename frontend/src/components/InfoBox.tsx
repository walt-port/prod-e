import React from 'react';

const InfoBox: React.FC = () => {
  return (
    // Outer container - Use flex to center the inner window
    <div className="h-full w-full flex items-center justify-center p-4">
      {/* Floating window element - Use inline border-radius */}
      <div
        className="w-[90%] h-[90%] flex flex-col bg-[#1f2335] border border-[#414868] overflow-hidden shadow-lg"
        style={{
          boxShadow: '0 0 10px rgba(255, 255, 255, 0.4)',
          borderRadius: '0.5rem',
        }}
      >
        {/* Title Bar - Keep inline padding */}
        <div
          className="bg-[#24283b] py-1 text-xs text-gray-400 border-b border-[#414868] flex justify-between items-center font-hermit"
          style={{ paddingLeft: '0.5rem', paddingRight: '0.5rem' }}
        >
          {/* Left side */}
          <div className="flex">
            <span style={{ paddingRight: '0.75rem' }}>File</span>
            <span style={{ paddingRight: '0.75rem' }}>Edit</span>
            <span style={{ paddingRight: '0.75rem' }}>View</span>
            <span>Help</span>
          </div>

          {/* Right side - Revert to inline margins */}
          <div className="flex items-center">
            {/* Divider before minimize */}
            <div className="h-[12px] border-l border-gray-400"></div>
            {/* Minimize span with margin */}
            <span style={{ marginLeft: '0.5rem' }}>_</span>
            {/* Divider with margin */}
            <div
              className="h-[12px] border-l border-gray-400"
              style={{ marginLeft: '0.5rem' }}
            ></div>
            {/* Square span with margin */}
            <span style={{ marginLeft: '0.5rem' }}>□</span>
            {/* Divider with margin */}
            <div
              className="h-[12px] border-l border-gray-400"
              style={{ marginLeft: '0.5rem' }}
            ></div>
            {/* X span with margin */}
            <span style={{ marginLeft: '0.5rem' }}>X</span>
          </div>
        </div>

        {/* Content Area - Use inline padding */}
        <div
          className="flex-grow text-sm text-[#c0caf5] overflow-y-auto font-hermit"
          style={{
            paddingTop: '0.5rem',
            paddingRight: '1rem',
            paddingBottom: '0.5rem',
            paddingLeft: '1.5rem',
          }}
        >
          <p className="mb-4">
            Welcome to "prod-e" – The Production Experience Showcase, a fully-functional AWS
            production environment built as a passion project to demonstrate modern cloud
            architecture principles. This infrastructure features a multi-container ECS cluster
            hosting a React TypeScript frontend, backend services, and comprehensive monitoring
            through Prometheus and Grafana – all balanced across availability zones with application
            load balancing. The architecture is defined and deployed using Infrastructure as Code
            principles through CDKTF in TypeScript, connecting to a dedicated PostgreSQL RDS
            database instance for persistent storage.
          </p>
          <p className="mb-4">
            Created from a deep interest in cloud infrastructure and DevOps methodologies, "prod-e"
            represents the culmination of years of technical knowledge and practical application.
            This project was born from my desire to build a complete end-to-end system that mirrors
            enterprise-grade deployments, allowing me to experiment with best practices and advanced
            configurations in a controlled yet realistic environment. The multi-service architecture
            demonstrates how complex systems can be elegantly orchestrated in the cloud.
          </p>
          <p>
            The infrastructure is managed through a robust CI/CD pipeline via GitHub Actions,
            ensuring consistent and reliable deployments. Post-deployment health checks
            automatically verify resource availability and configuration, with comprehensive
            reporting delivered via email. This showcase highlights the power of automation,
            infrastructure as code, and observability in modern application delivery – principles
            I've implemented throughout my technical career. "prod-e" stands as testament to the
            satisfaction that comes from building sophisticated cloud systems that simply work.
          </p>
        </div>

        {/* Status Bar - Setup for scrolling */}
        <div className="border-t border-[#414868] py-1 text-xs text-gray-400 overflow-hidden whitespace-nowrap font-hermit">
          {/* Inner container for scrolling content - Use flex */}
          <div className="flex" id="statusBarContent">
            {/* Content Section 1 - Add margin to first icon */}
            <span style={{ marginLeft: '1rem' }}>👤</span>
            <a
              href="https://waltryan.com"
              target="_blank"
              rel="noopener noreferrer"
              className="text-[#7aa2f7] hover:underline"
              style={{ marginLeft: '0.25rem' }}
            >
              waltryan.com
            </a>
            <span style={{ marginLeft: '1rem' }}>💻</span>
            <a
              href="https://waltryan.dev"
              target="_blank"
              rel="noopener noreferrer"
              className="text-[#7aa2f7] hover:underline"
              style={{ marginLeft: '0.25rem' }}
            >
              waltryan.dev
            </a>
            <span style={{ marginLeft: '1rem' }}>🔗</span>
            <a
              href="https://github.com/walt-port/prod-e"
              target="_blank"
              rel="noopener noreferrer"
              className="text-[#7aa2f7] hover:underline"
              style={{ marginLeft: '0.25rem' }}
            >
              GitHub:prod-e
            </a>
            {/* Content Section 2 (Duplicate) - Reduce starting margin */}
            <span style={{ marginLeft: '0.75rem' }}>👤</span> {/* Reduced margin */}
            <a
              href="https://waltryan.com"
              target="_blank"
              rel="noopener noreferrer"
              className="text-[#7aa2f7] hover:underline"
              style={{ marginLeft: '0.25rem' }}
            >
              waltryan.com
            </a>
            <span style={{ marginLeft: '1rem' }}>💻</span>
            <a
              href="https://waltryan.dev"
              target="_blank"
              rel="noopener noreferrer"
              className="text-[#7aa2f7] hover:underline"
              style={{ marginLeft: '0.25rem' }}
            >
              waltryan.dev
            </a>
            <span style={{ marginLeft: '1rem' }}>🔗</span>
            <a
              href="https://github.com/walt-port/prod-e"
              target="_blank"
              rel="noopener noreferrer"
              className="text-[#7aa2f7] hover:underline"
              style={{ marginLeft: '0.25rem' }}
            >
              GitHub:prod-e
            </a>
          </div>
        </div>
      </div>
    </div>
  );
};

export default InfoBox;
