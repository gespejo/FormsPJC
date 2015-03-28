package oracle.forms.ms.jung;

import edu.uci.ics.jung.algorithms.layout.PolarPoint;
import edu.uci.ics.jung.algorithms.layout.RadialTreeLayout;
import edu.uci.ics.jung.algorithms.layout.TreeLayout;
import edu.uci.ics.jung.graph.DelegateForest;
import edu.uci.ics.jung.graph.DelegateTree;
import edu.uci.ics.jung.graph.DirectedGraph;
import edu.uci.ics.jung.graph.DirectedSparseMultigraph;
import edu.uci.ics.jung.graph.Forest;
import edu.uci.ics.jung.graph.Tree;
import edu.uci.ics.jung.visualization.GraphZoomScrollPane;
import edu.uci.ics.jung.visualization.Layer;
import edu.uci.ics.jung.visualization.VisualizationServer;
import edu.uci.ics.jung.visualization.VisualizationViewer;
import edu.uci.ics.jung.visualization.control.CrossoverScalingControl;
import edu.uci.ics.jung.visualization.control.DefaultModalGraphMouse;
import edu.uci.ics.jung.visualization.control.ModalGraphMouse;
import edu.uci.ics.jung.visualization.control.ScalingControl;
import edu.uci.ics.jung.visualization.decorators.DefaultVertexIconTransformer;
import edu.uci.ics.jung.visualization.decorators.EdgeShape;
import edu.uci.ics.jung.visualization.decorators.EllipseVertexShapeTransformer;
import edu.uci.ics.jung.visualization.decorators.ToStringLabeller;
import edu.uci.ics.jung.visualization.decorators.VertexIconShapeTransformer;
import edu.uci.ics.jung.visualization.layout.LayoutTransition;
import edu.uci.ics.jung.visualization.util.Animator;

import java.awt.BorderLayout;
import java.awt.Color;
import java.awt.Dimension;
import java.awt.Graphics;
import java.awt.Graphics2D;
import java.awt.GridLayout;
import java.awt.Shape;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.awt.event.ItemEvent;
import java.awt.event.ItemListener;
import java.awt.geom.Ellipse2D;
import java.awt.geom.Point2D;

import java.util.Collection;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;

import javax.swing.BorderFactory;
import javax.swing.Icon;
import javax.swing.ImageIcon;
import javax.swing.JButton;
import javax.swing.JComboBox;
import javax.swing.JFrame;
import javax.swing.JPanel;
import javax.swing.JToggleButton;

import oracle.forms.ui.VBean;

import org.apache.commons.collections15.Factory;
import org.apache.commons.collections15.Transformer;
import org.apache.commons.collections15.functors.ConstantTransformer;


/**
 * Based on treelayout and radialtreelayout demonstration from JUNG.
 * @author Mark Striekwold
 *  
 */
public class orgTree extends VBean {
    /**
     * the graph
     */
    Forest<Integer,Integer> graph;
  
    Factory<DirectedGraph<String,Integer>> graphFactory = new Factory<DirectedGraph<String,Integer>>() {
                    public DirectedGraph<String, Integer> create() {
                            return new DirectedSparseMultigraph<String,Integer>();
                    }
    };
          
    Factory<Tree<String,Integer>> treeFactory = new Factory<Tree<String,Integer>> () {
            public Tree<String, Integer> create() {
                    return new DelegateTree<String,Integer>(graphFactory);
            }
    };
  
    Factory<Integer> edgeFactory = new Factory<Integer>() {
        int i=0;
        public Integer create() {
            return i++;
        }
              
        public Integer create (Integer j){
            return j;
        }
    };
  
    Factory<String> vertexFactory = new Factory<String>() {
        int i=0;
        public String create() {
            return "V"+i++;
        }};

    /**
     * the visual component and renderer for the graph
     */
    private VisualizationViewer<Integer,Integer> vv;
    private VisualizationServer.Paintable rings;
    private TreeLayout<Integer,Integer> treeLayout;
    private RadialTreeLayout<Integer,Integer> radialLayout;
    private LayoutTransition<Integer,Integer> lt;
    private JPanel jp;
    private JPanel controls;
    private JComboBox modeBox;
    private GraphZoomScrollPane panel;
    private DefaultModalGraphMouse graphMouse;
    private DefaultVertexIconTransformer<Integer> vertexIconFunction;
    private VertexIconShapeTransformer<Integer> vertexIconShapeFunction;
    private UnicodeVertexStringer<Integer> uvs;
    private Map<Integer, String> map;
    private boolean showLabels = true;
    private Integer[] v;
    
    class UnicodeVertexStringer<V> implements Transformer<V, String> {

        Map<V, String> map = new HashMap<V, String>();
        Map<V, Icon> iconMap = new HashMap<V, Icon>();

        public UnicodeVertexStringer(V[] vertices) {
        }

        /**
         * @see edu.uci.ics.jung.graph.decorators.VertexStringer#getLabel(edu.uci.ics.jung.graph.Vertex)
         */
        public String getLabel(V v) {
            if (showLabels) {
                return (String)map.get(v);
            } else {
                return "";
            }
        }

        public String transform(V input) {
            return getLabel(input);
        }
    }

    public orgTree() {
        jp = new JPanel();
        // create a simple graph for the demo
        graph = new DelegateForest<Integer,Integer>();
              
        uvs = new UnicodeVertexStringer<Integer>(v);
      
        vertexIconShapeFunction = new VertexIconShapeTransformer<Integer>(new EllipseVertexShapeTransformer<Integer>());
        vertexIconFunction = new DefaultVertexIconTransformer<Integer>();
        map = new HashMap<Integer, String>();

        createViewer();
        
        //Container content = getContentPane();
        panel = new GraphZoomScrollPane(vv);
        jp.add(panel);
      
        graphMouse = new DefaultModalGraphMouse();

        vv.setGraphMouse(graphMouse);
      
        modeBox = graphMouse.getModeComboBox();
        modeBox.addItemListener(graphMouse.getModeListener());
        graphMouse.setMode(ModalGraphMouse.Mode.TRANSFORMING);

        final ScalingControl scaler = new CrossoverScalingControl();

        JButton plus = new JButton("+");
        plus.addActionListener(new ActionListener() {
            public void actionPerformed(ActionEvent e) {
                scaler.scale(vv, 1.1f, vv.getCenter());
            }
        });
        JButton minus = new JButton("-");
        minus.addActionListener(new ActionListener() {
            public void actionPerformed(ActionEvent e) {
                scaler.scale(vv, 1/1.1f, vv.getCenter());
            }
        });

        JToggleButton radial = new JToggleButton("Radial");
        radial.addItemListener(new ItemListener() {
                public void itemStateChanged(ItemEvent e) {
                        if(e.getStateChange() == ItemEvent.SELECTED) {
                                lt = new LayoutTransition<Integer,Integer>(vv, treeLayout, radialLayout);
                                Animator animator = new Animator(lt);
                                animator.start();
                                vv.getRenderContext().getMultiLayerTransformer().setToIdentity();
                                vv.addPreRenderPaintable(rings);
                        } else {
                                lt = new LayoutTransition<Integer,Integer>(vv, radialLayout, treeLayout);
                                Animator animator = new Animator(lt);
                                animator.start();
                                vv.getRenderContext().getMultiLayerTransformer().setToIdentity();
                                vv.removePreRenderPaintable(rings);
                        }
                        vv.repaint();
                }});
 
        JPanel scaleGrid = new JPanel(new GridLayout(1,0));
        scaleGrid.setBorder(BorderFactory.createTitledBorder("Zoom"));

        controls = new JPanel();
        scaleGrid.add(plus);
        scaleGrid.add(minus);
        controls.add(radial);
        controls.add(scaleGrid);
        controls.add(modeBox);

        jp.add(controls);//, BorderLayout.SOUTH);
        add(jp);
    }
    
    private void createViewer(){
        uvs.map = map;      

        treeLayout = new TreeLayout<Integer,Integer>(graph);
        radialLayout = new RadialTreeLayout<Integer,Integer>(graph);
        radialLayout.setSize(new Dimension(600,450));
        vv =  new VisualizationViewer<Integer,Integer>(treeLayout, new Dimension(600,450));
        vv.setBackground(Color.white);
        vv.getRenderContext().setEdgeShapeTransformer(new EdgeShape.Line());
        vv.getRenderContext().setVertexLabelTransformer(uvs);    
        vv.getRenderContext().setVertexShapeTransformer(vertexIconShapeFunction);
        vv.getRenderContext().setVertexIconTransformer(vertexIconFunction);
        vertexIconShapeFunction.setIconMap(vertexIconFunction.getIconMap());
        // add a listener for ToolTips
        vv.setVertexToolTipTransformer(new ToStringLabeller());
        vv.getRenderContext().setArrowFillPaintTransformer(new ConstantTransformer(Color.lightGray));
        rings = new Rings();
    }
   
    public void init(Integer num){
        // create a array for the nodes
        v = new Integer[num];
    }
   
    public void addNode( String node, String  name, String parent ){
        addNode( Integer.parseInt( node)
               , name
               , Integer.parseInt( parent)
               );
    }
   
    public void addNode( Integer node, String  name, Integer parent ){
        graph.addVertex(node);
        map.put(node, name);

        vertexIconFunction.getIconMap().put(node, new ImageIcon(getClass().getResource("/images/person.gif")));
        
        // check if number is larger then zero, internal number from pk is larger
        if ( parent > 0){
           graph.addEdge(edgeFactory.create(), parent, node);
        }
    }
   
    public void showNodes(){
        
        createViewer();
        
        // remove everything of the panel and add the viewer again
        panel.removeAll();
        panel.add(new GraphZoomScrollPane(vv));
       
        graphMouse = new DefaultModalGraphMouse();

        vv.setGraphMouse(graphMouse);
        // remove modeBox which was part of the old viewer
        controls.remove(modeBox);
       
        modeBox = graphMouse.getModeComboBox();
        modeBox.addItemListener(graphMouse.getModeListener());
        graphMouse.setMode(ModalGraphMouse.Mode.TRANSFORMING);
        // add new modeBox
        controls.add(modeBox);
        vv.revalidate();
    }

    class Rings implements VisualizationServer.Paintable {
        Collection<Double> depths;
      
        public Rings() {
            depths = getDepths();
        }
      
        private Collection<Double> getDepths() {
            Set<Double> depths = new HashSet<Double>();
            Map<Integer,PolarPoint> polarLocations = radialLayout.getPolarLocations();
            for(Integer v : graph.getVertices()) {
                PolarPoint pp = polarLocations.get(v);
                depths.add(pp.getRadius());
            }
            return depths;
        }

        public void paint(Graphics g) {
            g.setColor(Color.lightGray);
      
            Graphics2D g2d = (Graphics2D)g;
            Point2D center = radialLayout.getCenter();

            Ellipse2D ellipse = new Ellipse2D.Double();
            for(double d : depths) {
                ellipse.setFrameFromDiagonal(center.getX()-d, center.getY()-d,
                        center.getX()+d, center.getY()+d);
                Shape shape = vv.getRenderContext().getMultiLayerTransformer().getTransformer(Layer.LAYOUT).transform(ellipse);
                g2d.draw(shape);
            }
        }

        public boolean useTransform() {
            return true;
        }
    }

    /**
     * a main method to run the application locally for test
     */
    public static void main(String[] args) {
        orgTree tld = new orgTree();
        JFrame frame = new JFrame();
        frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);

        frame.add(tld);

        frame.pack();
        frame.setVisible(true);
        tld.init(11);

        // addNode(String, String, String);
        tld.addNode( "110", "Jansen", "-1" );
        tld.addNode( "120", "Pietersen", "110" );
        tld.addNode( "130", "Pietersen", "110" );
        tld.addNode( "140", "De Vries", "130" );
        tld.addNode( "150", "Willemsen", "140" );

        // addNode (Integer, String, Integer);
        tld.addNode( 160, "Janszoon", -1 );
        tld.addNode( 170, "Anders", 160 );
        tld.addNode( 180, "Hans", 160 );
        tld.addNode( 190, "Ditzo", 160 );
        tld.addNode( 200, "Datzo", 180 );
      
        tld.showNodes();
    }
}
