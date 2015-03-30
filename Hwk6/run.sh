for i in "Alford" "Bolden" "Hamilton" "Parker" "Powell"
do
  echo $i "Getting Started"
  python mychatserver.py $i &
done
