
import java.io.*;
import java.util.*;
import oracle.sql.*;
import java.sql.*;
import java.math.BigDecimal;
import oracle.CartridgeServices.*;

// stored context type

public class StoredCtx
{
  ResultSet rset;
  public StoredCtx(ResultSet rs) { rset=rs; }
}

// implementation type

public class StockPivotImpl implements SQLData 
{
  private BigDecimal key;

  final static BigDecimal SUCCESS = new BigDecimal(0);
  final static BigDecimal ERROR = new BigDecimal(1);
  
  // Implement SQLData interface.

  String sql_type;
  public String getSQLTypeName() throws SQLException 
  {
    return sql_type;
  }

  public void readSQL(SQLInput stream, String typeName) throws SQLException 
  {
    sql_type = typeName;
    key = stream.readBigDecimal();
  }

  public void writeSQL(SQLOutput stream) throws SQLException 
  {
    stream.writeBigDecimal(key);
  }
  
  // type methods implementing ODCITable interface

  static public BigDecimal ODCITableStart(STRUCT[] sctx,ResultSet rset)
    throws SQLException 
  {
    Connection conn = DriverManager.getConnection("jdbc:default:connection:");

    // create a stored context and store the result set in it
    StoredCtx ctx=new StoredCtx(rset);

    // register stored context with cartridge services
    int key;
    try {
      key = ContextManager.setContext(ctx);
    } catch (CountException ce) {
      return ERROR;
    }

    // create a StockPivotImpl instance and store the key in it
    Object[] impAttr = new Object[1];
    impAttr[0] = new BigDecimal(key); 
    StructDescriptor sd = new StructDescriptor("STOCKPIVOTIMPL",conn);
    sctx[0] = new STRUCT(sd,conn,impAttr);
      
    return SUCCESS;
  }

  public BigDecimal ODCITableFetch(BigDecimal nrows, ARRAY[] outSet)
    throws SQLException 
  {
    Connection conn = DriverManager.getConnection("jdbc:default:connection:");

    // retrieve stored context using the key
    StoredCtx ctx;
    try {
      ctx=(StoredCtx)ContextManager.getContext(key.intValue());
    } catch (InvalidKeyException ik ) {
      return ERROR;
    }

    // get the nrows parameter, but return up to 10 rows
    int nrowsval = nrows.intValue();
    if (nrowsval>10) nrowsval=10;

    // create a vector for the fetched rows
    Vector v = new Vector(nrowsval);
    int i=0;

    StructDescriptor outDesc = 
      StructDescriptor.createDescriptor("TICKERTYPE", conn);
    Object[] out_attr = new Object[3];

    while(nrowsval>0 && ctx.rset.next()){
      out_attr[0] = (Object)ctx.rset.getString(1);
      out_attr[1] = (Object)new String("O");
      out_attr[2] = (Object)new BigDecimal(ctx.rset.getFloat(2));
      v.add((Object)new STRUCT(outDesc, conn, out_attr));

      out_attr[1] = (Object)new String("C");
      out_attr[2] = (Object)new BigDecimal(ctx.rset.getFloat(3));
      v.add((Object)new STRUCT(outDesc, conn, out_attr));

      i+=2;
      nrowsval-=2;
    }

    // return if no rows found
    if(i==0) return SUCCESS;

    // create the output ARRAY using the vector
    Object out_arr[] = v.toArray();
    ArrayDescriptor ad = new ArrayDescriptor("TICKERTYPESET",conn);
    outSet[0] = new ARRAY(ad,conn,out_arr);
   
    return SUCCESS;
  }

  public BigDecimal ODCITableClose() throws SQLException {
    
    // retrieve stored context using the key, and remove from ContextManager
    StoredCtx ctx;
    try {
      ctx=(StoredCtx)ContextManager.clearContext(key.intValue());
    } catch (InvalidKeyException ik ) {
      return ERROR;
    }

    // close the result set
    Statement stmt = ctx.rset.getStatement();
    ctx.rset.close();
    if(stmt!=null) stmt.close();

    return SUCCESS;
  }

}
