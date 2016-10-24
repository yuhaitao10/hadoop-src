/* SimpleApp, scala*/
import org.apache.spark.SparkContext
import org.apache.spark.SparkContext._
import org.apache.spark.SparkConf

object DataFramePeople {
  def main(args: Array[String]) {
    case class Person(name: String, age: Long, salary: Long, birthday: String)
    val logFile = "hdfs://quickstart.cloudera:8020/user/spark/applicationHistory/people.txt" // Should be some file on your system
    //val conf = new SparkConf().setAppName("Word Count Application")
    //val sc = new SparkContext(conf)
    val sc = new SparkContext("local", "Simple", "/usr/bin",List("target/scala-2.11/wordcount_2.11-1.0.jar"))

    val peopleRDD = sc.textFile(logFile, 2).cache()

    val plDF = peopleRDD.map(x => x.split(",")).map(attributes=>Person(attributes(0),attributes(1).trim.toInt, attributes(2).trim.toInt, attributes(3))).toDF

    plDF.select("name","age").show(2)   
   /* plDF.select("name","age").show(2,false)
    plDF.select("name").groupBy("name").count().orderBy("count").show
    plDF.select("*").orderBy("salary").show

    val count1 = logData.flatMap( x => x.split(" ")).map(x => (x,1)).reduceByKey(_+_)
    val count2 = logData.flatMap( x => x.split(" ")).map(x => (x,1)).reduceByKey((a,b) => (a+b))

    val tot1 = count1.count();
    val tot2 = count2.count();

    println("At At At At At At At At At At begining")
    println("Total Number of words: %s  Total Number of words %s".format(tot1, tot2))
    println("At At At At end of the job")*/
  }
}
