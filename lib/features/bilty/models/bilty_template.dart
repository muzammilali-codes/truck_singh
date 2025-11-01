class BiltyTemplate {
  final String name;
  final String version;
  final String layout;
  final List<BiltySection> sections;

  BiltyTemplate({
    required this.name,
    required this.version,
    required this.layout,
    required this.sections,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'version': version,
      'layout': layout,
      'sections': sections.map((section) => section.toJson()).toList(),
    };
  }

  factory BiltyTemplate.fromJson(Map<String, dynamic> json) {
    return BiltyTemplate(
      name: json['name'] ?? '',
      version: json['version'] ?? '',
      layout: json['layout'] ?? '',
      sections: (json['sections'] as List?)
          ?.map((section) => BiltySection.fromJson(section))
          .toList() ?? [],
    );
  }

  static BiltyTemplate get defaultTemplate => BiltyTemplate(
    name: "Professional Transport Bilty",
    version: "1.0",
    layout: "two_column_header",
    sections: [
      // Header Section
      BiltySection(
        sectionId: "header",
        type: "header",
        elements: [
          BiltyElement(
            id: "logo",
            type: "image_placeholder",
            label: "Company Logo",
          ),
          BiltyElement(
            id: "company_name",
            type: "static_text",
            content: "Transport Company Name",
            style: "h1",
          ),
          BiltyElement(
            id: "copy_type",
            type: "static_text",
            content: "Original - Consignor Copy",
            style: "watermark",
          ),
        ],
      ),

      // Primary Details Section
      BiltySection(
        sectionId: "primary_details",
        type: "grid",
        columns: 2,
        elements: [
          BiltyElement(
            id: "bilty_no",
            label: "Bilty No.:",
            type: "text_input",
            placeholder: "Enter Bilty Number",
          ),
          BiltyElement(
            id: "date",
            label: "Date:",
            type: "date_picker",
            placeholder: "Select Date",
          ),
          BiltyElement(
            id: "sender_details",
            label: "Sender Name & Address:",
            type: "text_area",
            lines: 3,
          ),
          BiltyElement(
            id: "truck_no",
            label: "Truck No.:",
            type: "text_input",
          ),
          BiltyElement(
            id: "recipient_details",
            label: "Recipient Name & Address:",
            type: "text_area",
            lines: 3,
          ),
          BiltyElement(
            id: "from_where",
            label: "From Where:",
            type: "text_input",
          ),
          BiltyElement(
            id: "truck_owner_name",
            label: "Truck Owner Name:",
            type: "text_input",
          ),
          BiltyElement(
            id: "till_where",
            label: "Till Where:",
            type: "text_input",
          ),
          BiltyElement(
            id: "engine_no",
            label: "Engine No.:",
            type: "text_input",
          ),
          BiltyElement(
            id: "driver_name",
            label: "Driver Name:",
            type: "text_input",
          ),
          BiltyElement(
            id: "driver_phone",
            label: "Driver Phone:",
            type: "text_input",
          ),
          BiltyElement(
            id: "driver_license",
            label: "Driver License:",
            type: "text_input",
          ),
          BiltyElement(
            id: "vehicle_type",
            label: "Vehicle Type:",
            type: "text_input",
          ),
          BiltyElement(
            id: "transporter_name",
            label: "Transporter Name:",
            type: "text_input",
          ),
          BiltyElement(
            id: "transporter_gstin",
            label: "Transporter GSTIN:",
            type: "text_input",
          ),
          BiltyElement(
            id: "delivery_date",
            label: "Delivery Date:",
            type: "date_picker",
          ),
        ],
      ),

      // Goods and Charges Section
      BiltySection(
        sectionId: "goods_and_charges",
        type: "table",
        label: "Goods & Charges",
        tableColumns: [
          BiltyColumn(id: "sr_no", header: "#"),
          BiltyColumn(id: "description", header: "Description"),
          BiltyColumn(id: "weight", header: "Weight (kg)"),
          BiltyColumn(id: "quantity", header: "Quantity"),
          BiltyColumn(id: "rate", header: "Rate (₹)"),
          BiltyColumn(id: "amount", header: "Amount (₹)"),
          BiltyColumn(id: "remarks", header: "Remarks"),
        ],
        elements: [],
        allowAddRow: true,
      ),

      // Charges Section
      BiltySection(
        sectionId: "charges",
        type: "grid",
        columns: 2,
        elements: [
          BiltyElement(
            id: "basic_fare",
            label: "Basic Fare (₹):",
            type: "number_input",
          ),
          BiltyElement(
            id: "other_charges",
            label: "Other Charges (₹):",
            type: "number_input",
          ),
          BiltyElement(
            id: "gst",
            label: "GST (₹):",
            type: "number_input",
          ),
          BiltyElement(
            id: "total_amount",
            label: "Total Amount (₹):",
            type: "number_input",
            readOnly: true,
          ),
          BiltyElement(
            id: "payment_status",
            label: "Payment Status:",
            type: "dropdown",
            options: ["Paid", "To Pay", "Partial"],
          ),
        ],
      ),

      // Extra Charges Section
      BiltySection(
        sectionId: "extra_charges_and_vehicle",
        type: "grid",
        columns: 2,
        elements: [
          BiltyElement(
            id: "extra_charges",
            label: "Extra Charges",
            type: "checkbox_group",
            checkboxOptions: [
              BiltyOption(id: "labour_charge", label: "Labour Charge"),
              BiltyOption(id: "fork_expense", label: "Fork Expense"),
              BiltyOption(id: "detention_charge", label: "Detention Charge"),
              BiltyOption(id: "loading_charge", label: "Loading Charge"),
              BiltyOption(id: "unloading_charge", label: "Unloading Charge"),
              BiltyOption(id: "insurance_charge", label: "Insurance Charge"),
              BiltyOption(id: "other_charges", label: "Other Charges"),
            ],
          ),
          BiltyElement(
            id: "vehicle_image",
            type: "image_placeholder",
            label: "Vehicle Image",
          ),
        ],
      ),

      // Bank Details Section
      BiltySection(
        sectionId: "bank_details",
        type: "grid",
        columns: 2,
        elements: [
          BiltyElement(
            id: "bank_name",
            label: "Bank Name:",
            type: "text_input",
          ),
          BiltyElement(
            id: "account_name",
            label: "Account Name:",
            type: "text_input",
          ),
          BiltyElement(
            id: "account_no",
            label: "Account No.:",
            type: "text_input",
          ),
          BiltyElement(
            id: "ifsc_code",
            label: "IFSC Code:",
            type: "text_input",
          ),
        ],
      ),

      // Terms and Signatures Section
      BiltySection(
        sectionId: "footer",
        type: "grid",
        columns: 2,
        elements: [
          BiltyElement(
            id: "terms",
            label: "Terms and Conditions",
            type: "static_text",
            content: """1. The trader should load the goods only after completing all the vehicle documents.
2. Insurance of goods more than Rs. 10,000/- is a must.
3. Goods will be transported at owner's risk.
4. Payment should be made as per agreed terms.
5. Any dispute will be subject to local jurisdiction.
6. E-way bill compliance is mandatory for GST registered businesses.
7. Delivery will be made only to the authorized person.
8. Detention charges will be applicable for delays beyond control.""",
          ),
          BiltyElement(
            id: "signatures",
            type: "group",
            groupElements: [
              BiltyElement(
                id: "sender_signature",
                label: "Sender Signature",
                type: "signature_pad",
              ),
              BiltyElement(
                id: "driver_signature",
                label: "Driver's Signature",
                type: "signature_pad",
              ),
              BiltyElement(
                id: "clerk_signature",
                label: "Booking Clerk",
                type: "signature_pad",
              ),
            ],
          ),
        ],
      ),

      // Remarks Section
      BiltySection(
        sectionId: "remarks",
        type: "single",
        elements: [
          BiltyElement(
            id: "remarks",
            label: "Special Instructions / Remarks:",
            type: "text_area",
            lines: 3,
          ),
        ],
      ),
    ],
  );
}

class BiltySection {
  final String sectionId;
  final String type;
  final int? columns;
  final String? label;
  final List<BiltyElement> elements;
  final List<BiltyColumn>? tableColumns;
  final bool? allowAddRow;

  BiltySection({
    required this.sectionId,
    required this.type,
    this.columns,
    this.label,
    required this.elements,
    this.tableColumns,
    this.allowAddRow,
  });

  Map<String, dynamic> toJson() {
    return {
      'section_id': sectionId,
      'type': type,
      if (columns != null) 'columns': columns,
      if (label != null) 'label': label,
      'elements': elements.map((element) => element.toJson()).toList(),
      if (tableColumns != null) 'columns': tableColumns!.map((col) => col.toJson()).toList(),
      if (allowAddRow != null) 'allow_add_row': allowAddRow,
    };
  }

  factory BiltySection.fromJson(Map<String, dynamic> json) {
    return BiltySection(
      sectionId: json['section_id'] ?? '',
      type: json['type'] ?? '',
      columns: json['columns'],
      label: json['label'],
      elements: (json['elements'] as List?)
          ?.map((element) => BiltyElement.fromJson(element))
          .toList() ?? [],
      tableColumns: (json['columns'] as List?)
          ?.map((col) => BiltyColumn.fromJson(col))
          .toList(),
      allowAddRow: json['allow_add_row'],
    );
  }
}

class BiltyElement {
  final String id;
  final String type;
  final String? label;
  final String? content;
  final String? placeholder;
  final String? style;
  final int? lines;
  final bool? readOnly;
  final List<String>? options;
  final List<BiltyOption>? checkboxOptions;
  final List<BiltyElement>? groupElements;

  BiltyElement({
    required this.id,
    required this.type,
    this.label,
    this.content,
    this.placeholder,
    this.style,
    this.lines,
    this.readOnly,
    this.options,
    this.checkboxOptions,
    this.groupElements,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      if (label != null) 'label': label,
      if (content != null) 'content': content,
      if (placeholder != null) 'placeholder': placeholder,
      if (style != null) 'style': style,
      if (lines != null) 'lines': lines,
      if (readOnly != null) 'read_only': readOnly,
      if (options != null) 'options': options,
      if (checkboxOptions != null) 'options': checkboxOptions!.map((opt) => opt.toJson()).toList(),
      if (groupElements != null) 'elements': groupElements!.map((element) => element.toJson()).toList(),
    };
  }

  factory BiltyElement.fromJson(Map<String, dynamic> json) {
    return BiltyElement(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      label: json['label'],
      content: json['content'],
      placeholder: json['placeholder'],
      style: json['style'],
      lines: json['lines'],
      readOnly: json['read_only'],
      options: (json['options'] as List?)?.cast<String>(),
      checkboxOptions: (json['options'] as List?)
          ?.map((opt) => BiltyOption.fromJson(opt))
          .toList(),
      groupElements: (json['elements'] as List?)
          ?.map((element) => BiltyElement.fromJson(element))
          .toList(),
    );
  }
}

class BiltyColumn {
  final String id;
  final String header;

  BiltyColumn({
    required this.id,
    required this.header,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'header': header,
    };
  }

  factory BiltyColumn.fromJson(Map<String, dynamic> json) {
    return BiltyColumn(
      id: json['id'] ?? '',
      header: json['header'] ?? '',
    );
  }
}

class BiltyOption {
  final String id;
  final String label;

  BiltyOption({
    required this.id,
    required this.label,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
    };
  }

  factory BiltyOption.fromJson(Map<String, dynamic> json) {
    return BiltyOption(
      id: json['id'] ?? '',
      label: json['label'] ?? '',
    );
  }
}
