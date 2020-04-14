const sortData = (data, fieldname, direction) => {
	let parseData = JSON.parse(JSON.stringify(data)); // serialize the data before calling sort function
	let keyValue = a => {
		// Return the value stored in the field
		return a[fieldname];
	};
	let isReverse = direction === "asc" ? 1 : -1; // cheking reverse direction
	parseData.sort((x, y) => {
		// sorting data
		x = keyValue(x) ? keyValue(x) : ""; // handling null values
		y = keyValue(y) ? keyValue(y) : "";
		return isReverse * ((x > y) - (y > x)); // sorting values based on direction
	});
	return parseData;
};