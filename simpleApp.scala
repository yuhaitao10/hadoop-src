/* SimpleApp, scala*/
import org.apache.spark.SparkContext
import org.apache.spark.SparkContext._
import org.apache.spark.SparkConf

object SimpleApp {
  def main(args: Array[String]) {
    val logFile = "hdfs://quickstart.cloudera:8020/user/spark/applicationHistory/textinput.txt" // Should be some file on your system
    val conf = new SparkConf().setAppName("Simple Application")
    //val sc = new SparkContext(conf)
    val sc = new SparkContext("local", "Simple", "/usr/bin",List("target/scala-2.11/simple-project_2.11-1.0.jar"))

    val logData = sc.textFile(logFile, 2).cache()
    println("At At At At First")
    logData.foreach(println)
    val numAs = logData.filter(line => line.contains("a")).count()
    println("At At At At Second")
    val numBs = logData.filter(line => line.contains("b")).count()
    println("At At At At Third")
    println("Lines with a: %s, Lines with b: %s".format(numAs, numBs))
    println("At At At At end of the job")
  }
}
