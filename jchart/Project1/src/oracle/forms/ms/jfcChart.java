package oracle.forms.ms;

import oracle.forms.ui.VBean;

public class jfcChart extends VBean {

    final String pieType = "PIE";
    final String barType = "BAR";
    private String chartType;
    private jfcBar jfcB;
    private jfcPie jfcP;

    public jfcChart() {
        jfcB = new jfcBar();
        jfcP = new jfcPie();
    }

    public void setChartType(String cType){
       chartType = new String (cType);
    }
    
    public void clearDataset(){
       if (chartType.equals(pieType)){
           jfcP.clearDataset();
       }
       else{
           jfcB.clearDataset();
       }
    }
    
    public void setTitle(String title){
        if (chartType.equals(pieType)){
            jfcP.setTitle(title);
        }
        else{
            jfcB.setTitle(title);
        }
    }

    public void setValue ( String bValue, String bName, String bSerie )
    {
        if (chartType.equals(pieType)){
            jfcP.setValue(bValue, bName);
        }
        else{
            jfcB.setValue(bValue, bSerie, bName);
        }
    }
  
    public void createDemoPanel() {
        if (chartType.equals(pieType)){
            jfcP.createDemoPanel();
            add(jfcP);
        }
        else{
            jfcP.removeAll();
            jfcB.removeAll();
            jfcB.createDemoPanel();
            add(jfcB);
        }
    }

   public void removeChart(){
       if (chartType.equals(pieType)){
           jfcB.removeChart();
       }
       if (chartType.equals(barType)){
           jfcP.removeChart();       
       }
   }
    
}
