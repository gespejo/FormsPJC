package oracle.forms.ms;

import java.awt.Font;

import javax.swing.JPanel;

import oracle.forms.ui.VBean;

import org.jfree.chart.ChartFactory;
import org.jfree.chart.ChartPanel;
import org.jfree.chart.JFreeChart;
import org.jfree.chart.plot.PiePlot;
import org.jfree.data.general.DefaultPieDataset;


public class jfcPie extends VBean {

    private DefaultPieDataset dataset;
    private String pieTitle;
    private ChartPanel cP;
    public jfcPie() {
        dataset = new DefaultPieDataset();
    }

    public void clearDataset(){
        dataset.clear();
    }
    
    public void setTitle(String title){
        pieTitle = new String(title);
    }

    public void setValue ( String cValue, String cName )
    {
        dataset.setValue(cName, new Double(cValue));
    }
        
    public JFreeChart createChart() {
           JFreeChart chart = ChartFactory.createPieChart(
                pieTitle,  // chart title
                dataset,   // data
                true,      // include legend
                true,
                false
            );

            PiePlot plot = (PiePlot) chart.getPlot();
            plot.setLabelFont(new Font("SansSerif", Font.PLAIN, 12));
            plot.setNoDataMessage("No data available");
            plot.setCircular(false);
            plot.setLabelGap(0.02);
            return chart;
    }
    
    public void  removeChart(){
        remove(cP);
    }
    
    public void createDemoPanel() {
      JFreeChart chart = createChart();
      cP = new ChartPanel(chart);
      add(cP);
    } 
    

}

