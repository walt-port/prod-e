import dagre from 'dagre';
import React, { useCallback } from 'react';
import ReactFlow, {
  addEdge,
  Background,
  Connection,
  Controls,
  Edge,
  MarkerType,
  Node,
  Position,
  useEdgesState,
  useNodesState,
} from 'reactflow';

import 'reactflow/dist/style.css';
import DatabaseNode from './diagram_nodes/DatabaseNode'; // Import
import LambdaNode from './diagram_nodes/LambdaNode'; // Import LambdaNode
import LoadBalancerNode from './diagram_nodes/LoadBalancerNode'; // Import
import ServiceNode from './diagram_nodes/ServiceNode'; // Import custom node
import UserNode from './diagram_nodes/UserNode'; // Import

// Define node types
const nodeTypes = {
  service: ServiceNode,
  user: UserNode, // Register
  loadbalancer: LoadBalancerNode, // Register
  database: DatabaseNode, // Register
  lambda: LambdaNode, // Register lambda type
  // Add other custom node types here later (e.g., database, loadbalancer)
};

// --- Dagre Layout Helper ---
const dagreGraph = new dagre.graphlib.Graph();
dagreGraph.setDefaultEdgeLabel(() => ({}));

const nodeWidth = 172; // Adjust as needed based on node size
const nodeHeight = 50; // Adjust as needed

const getLayoutedElements = (nodes: Node[], edges: Edge[], direction = 'TB') => {
  const isHorizontal = direction === 'LR';
  dagreGraph.setGraph({ rankdir: direction });

  nodes.forEach(node => {
    // Use node dimensions from custom nodes if possible, otherwise default
    // For simplicity now, we use default, but could fetch dynamically
    dagreGraph.setNode(node.id, { width: nodeWidth, height: nodeHeight });
  });

  edges.forEach(edge => {
    dagreGraph.setEdge(edge.source, edge.target);
  });

  dagre.layout(dagreGraph);

  nodes.forEach(node => {
    const nodeWithPosition = dagreGraph.node(node.id);
    node.targetPosition = isHorizontal ? Position.Left : Position.Top;
    node.sourcePosition = isHorizontal ? Position.Right : Position.Bottom;

    // We are shifting the dagre node position (anchor=center center) to the top left
    // so it matches the React Flow node anchor point (top left).
    node.position = {
      x: nodeWithPosition.x - nodeWidth / 2,
      y: nodeWithPosition.y - nodeHeight / 2,
    };

    return node;
  });

  return { nodes, edges };
};

// --- Node Definitions (Add dummy positions for TS) ---
const initialNodes: Node[] = [
  {
    id: 'internet',
    type: 'user',
    position: { x: 0, y: 0 }, // Dummy position for TS
    data: { label: 'Internet / User' },
  },
  {
    id: 'alb',
    type: 'loadbalancer',
    position: { x: 0, y: 0 }, // Dummy position for TS
    data: { label: 'prod-e-alb' },
  },
  {
    id: 'ecs-app',
    type: 'service',
    position: { x: 0, y: 0 }, // Dummy position for TS
    data: { label: 'prod-e-app' },
  },
  {
    id: 'ecs-backend',
    type: 'service',
    position: { x: 0, y: 0 }, // Dummy position for TS
    data: { label: 'prod-e-backend' },
  },
  {
    id: 'ecs-grafana',
    type: 'service',
    position: { x: 0, y: 0 }, // Dummy position for TS
    data: { label: 'prod-e-grafana' },
  },
  {
    id: 'ecs-prometheus',
    type: 'service',
    position: { x: 0, y: 0 }, // Dummy position for TS
    data: { label: 'prod-e-prometheus' },
  },
  {
    id: 'rds',
    type: 'database',
    position: { x: 0, y: 0 }, // Dummy position for TS
    data: { label: 'prod-e-db' },
  },
  {
    id: 'lambda-api',
    type: 'lambda',
    position: { x: 0, y: 0 }, // Dummy position for TS
    data: { label: 'prod-e-api' },
  },
];

// --- Edge Definitions (no changes needed here) ---
const edgeStyle = {
  // Common style for reuse
  stroke: '#7aa2f7',
};
const dbEdgeStyle = {
  stroke: '#bb9af7',
};
const monitoringEdgeStyle = {
  stroke: '#e0af68', // Orange for monitoring connections
};
// const apiEdgeStyle = { // <<< Remove unused style
//   stroke: '#e0af68',
// };
const appApiEdgeStyle = {
  stroke: '#9ece6a',
};

const initialEdges: Edge[] = [
  {
    id: 'e-internet-alb',
    source: 'internet',
    target: 'alb',
    markerEnd: { type: MarkerType.ArrowClosed, color: edgeStyle.stroke },
    style: edgeStyle,
    animated: true,
    type: 'smoothstep',
  },
  {
    id: 'e-alb-app',
    source: 'alb',
    target: 'ecs-app',
    markerEnd: { type: MarkerType.ArrowClosed, color: edgeStyle.stroke },
    style: edgeStyle,
    animated: true,
    type: 'smoothstep',
  },
  {
    id: 'e-alb-backend',
    source: 'alb',
    target: 'ecs-backend',
    markerEnd: { type: MarkerType.ArrowClosed, color: edgeStyle.stroke },
    style: edgeStyle,
    animated: true,
    type: 'smoothstep',
  },
  {
    id: 'e-alb-grafana',
    source: 'alb',
    target: 'ecs-grafana',
    markerEnd: { type: MarkerType.ArrowClosed, color: edgeStyle.stroke },
    style: edgeStyle,
    animated: true,
    type: 'smoothstep',
  },
  {
    id: 'e-backend-rds',
    source: 'ecs-backend',
    target: 'rds',
    markerEnd: { type: MarkerType.ArrowClosed, color: dbEdgeStyle.stroke },
    style: dbEdgeStyle,
    animated: true,
    type: 'smoothstep',
  },
  {
    id: 'e-app-rds',
    source: 'ecs-app',
    target: 'rds',
    markerEnd: { type: MarkerType.ArrowClosed, color: dbEdgeStyle.stroke },
    style: dbEdgeStyle,
    animated: true,
    type: 'smoothstep',
  },
  {
    id: 'e-grafana-prometheus',
    source: 'ecs-grafana',
    target: 'ecs-prometheus',
    markerEnd: { type: MarkerType.ArrowClosed, color: monitoringEdgeStyle.stroke },
    style: monitoringEdgeStyle,
    animated: true,
    type: 'smoothstep',
  },
  {
    id: 'e-app-lambda',
    source: 'ecs-app',
    target: 'lambda-api',
    markerEnd: { type: MarkerType.ArrowClosed, color: appApiEdgeStyle.stroke },
    style: appApiEdgeStyle,
    animated: true,
    type: 'smoothstep',
  },
];

// --- Calculate Layout ---
const { nodes: layoutedNodes, edges: layoutedEdges } = getLayoutedElements(
  initialNodes,
  initialEdges
);

const InfrastructureDiagram: React.FC = () => {
  // Remove unused setNodes
  const [nodes, , onNodesChange] = useNodesState(layoutedNodes);
  const [edges, setEdges, onEdgesChange] = useEdgesState(layoutedEdges);

  const onConnect = useCallback(
    (params: Connection | Edge) => setEdges(eds => addEdge(params, eds)),
    [setEdges]
  );

  // Reset layout on demand? (Could add a button later)

  return (
    <div style={{ width: '100%', height: '100%' }}>
      <ReactFlow
        nodes={nodes}
        edges={edges}
        onNodesChange={onNodesChange}
        onEdgesChange={onEdgesChange}
        onConnect={onConnect}
        fitView // Zoom to fit initially
        nodeTypes={nodeTypes} // Pass custom node types
        // ProOptions could hide attribution if needed later
        // proOptions={{ hideAttribution: true }}
      >
        <Controls position="bottom-left" />
        <Background color="#414868" gap={16} />
      </ReactFlow>
    </div>
  );
};

export default InfrastructureDiagram;
