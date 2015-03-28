package oracle.forms.ms;

import javax.swing.JFrame;
import javax.swing.JPanel;

public class jfcTest extends JPanel
{
    public static void main(String[] args)
    {
   /*
        jfcPie jPie = new jfcPie();
        
        jPie.clearDataset();
        jPie.setTitle("Pie Demo");
        jPie.setValue("Eén",  "43.2");
        jPie.setValue("Twee", "10.0");
        jPie.setValue("Drie", "27.5");
        jPie.setValue("Vier", "17.5");
        jPie.setValue("Zes",  "19.4");
        
        jPie.createDemoPanel();
   */     
        jfcChart jPie = new jfcChart();
        jPie.setChartType("PIE");
        jPie.clearDataset();        
        jPie.setValue("43.2", "Eén", "" );
        jPie.setValue("10.0", "Twee", "" );
        jPie.setValue("27.5", "Drie", "" );
        jPie.setValue("17.5", "Vier", "" );
        jPie.setValue("11.0", "Vijf", "");
        jPie.createDemoPanel();
        
        JFrame jf = new JFrame();
        jf.add(jPie);
        jf.setVisible(true);
  
         jfcChart jBar = new jfcChart();
         jBar.setChartType("BAR");

         jBar.setTitle("Bar Demo");
         String series1 = "Eerste";
         String series2 = "Tweede";
         String series3 = "Derde";

         // column keys...
         String category1 = "Category 1";
         String category2 = "Category 2";
         String category3 = "Category 3";
         String category4 = "Category 4";
         String category5 = "Category 5";

         jBar.setValue("1.0", series1, category1);
         jBar.setValue("4.0", series1, category2);
         jBar.setValue("3.0", series1, category3);
         jBar.setValue("5.0", series1, category4);
         jBar.setValue("5.0", series1, category5);

         jBar.setValue("5.0", series2, category1);
         jBar.setValue("7.0", series2, category2);
         jBar.setValue("6.0", series2, category3);
         jBar.setValue("8.0", series2, category4);
         jBar.setValue("4.0", series2, category5);

         jBar.setValue("4.0", series3, category1);
         jBar.setValue("3.0", series3, category2);
         jBar.setValue("2.0", series3, category3);
         jBar.setValue("3.0", series3, category4);
         jBar.setValue("6.0", series3, category5);
         
         jBar.createDemoPanel();
         
         jf = new JFrame();
         jf.add(jBar);
         jf.setVisible(true); 
    }
}

