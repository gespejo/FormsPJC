/*
 * Created on May 13, 2005
 *
 */
package oracle.forms.ms;

import java.io.File;

import javax.swing.filechooser.FileFilter;

/**
 * @author Gerald Holmann
 *
 */
public class PDFFileFilter extends FileFilter
{

    private boolean m_AllowDirs = true;

    public boolean accept(File f)
    {
        if (f.isDirectory() && m_AllowDirs)
        {
            return true;
        }
        else if ("pdf".equalsIgnoreCase(getExtension(f)))
        {
            return true;
        }

        return false;
    }

    public String getDescription()
    {
        return null;
    }
    
    private String getExtension(File f) 
    {
        String ext = null;
        String s = f.getName();
        int i = s.lastIndexOf('.');

        if (i > 0 &&  i < s.length() - 1) 
        {
            ext = s.substring(i+1).toLowerCase();
        }
        return ext;
    }
    
	public void setAllowDirs (boolean allowDirs)
	{
	    m_AllowDirs = allowDirs;
	}
}
