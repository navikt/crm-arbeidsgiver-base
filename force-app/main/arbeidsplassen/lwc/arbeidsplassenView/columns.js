export default {
	columns: [
		{
			label: "",
			fieldName: "empty",
			type: "date-local",

			fixedWidth: 15,
			typeAttributes: { year: "numeric", month: "2-digit", day: "2-digit" },
		},
		{
			label: "Frist",
			fieldName: "applicationDue",
			type: "date-local",

			sortable: true,
			fixedWidth: 100,
			typeAttributes: { year: "numeric", month: "2-digit", day: "2-digit" },
		},
		{
			label: "Tittel",
			fieldName: "title",
			type: "text",

			sortable: true,
			initialWidth: 300,
		},
		{
			label: "Sted",
			fieldName: "city",
			type: "text",

			sortable: true,
		},
		{
			label: "Form",
			fieldName: "engagementtype",
			type: "text",

			sortable: true,
		},
		{
			label: "Type",
			type: "text",
			fieldName: "extent",

			sortable: true,
		},
		{
			label: "Publisert",
			fieldName: "published",
			type: "date-local",

			sortable: true,
			fixedWidth: 100,
			typeAttributes: { year: "numeric", month: "2-digit", day: "2-digit" },
		},
		{
			label: "",
			fieldName: "url",
			type: "button",

			fixedWidth: 100,
			typeAttributes: {
				name: "openUrl",
				value: 'openUrl',
				target: "_self",
				label: 'Se på nav.no',
				title: 'Se på nav.no',
				variant: "base",
			}
		},
	]
};