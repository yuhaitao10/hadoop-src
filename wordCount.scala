/* SimpleApp, scala*/
import org.apache.spark.SparkContext
import org.apache.spark.SparkContext._
import org.apache.spark.SparkConf

object WordCount {
  def main(args: Array[String]) {
    val logFile = "hdfs://quickstart.cloudera:8020/user/spark/applicationHistory/textinput.txt" // Should be some file on your system
    val conf = new SparkConf().setAppName("Word Count Application")
    //val sc = new SparkContext(conf)
    val sc = new SparkContext("local", "Simple", "/usr/bin",List("target/scala-2.11/wordcount_2.11-1.0.jar"))

    val logData = sc.textFile(logFile, 2).cache()

    val count1 = logData.flatMap( x => x.split(" ")).map(x => (x,1)).reduceByKey(_+_)
    val count2 = logData.flatMap( x => x.split(" ")).map(x => (x,1)).reduceByKey((a,b) => (a+b))

    val tot1 = count1.count();
    val tot2 = count2.count();

    println("At At At At At At At At At At begining")
    println("Total Number of words: %s  Total Number of words %s".format(tot1, tot2))
    println("At At At At end of the job")
  }
}
