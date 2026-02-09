# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Demo user for development
if Rails.env.development?
  demo_user = User.find_or_initialize_by(email: "demo@example.com")
  demo_user.assign_attributes(
    password: "password123",
    password_confirmation: "password123",
    name: "Demo User",
    business_name: "Acme Consulting",
    address: "123 Main Street\nNew York, NY 10001",
    language: :en
  )
  demo_user.save!

  puts "Demo user created/updated:"
  puts "  Email: demo@example.com"
  puts "  Password: password123"

  # Demo clients
  clients_data = [
    { name: "Alice Johnson", email: "alice@techstartup.io", company: "Tech Startup Inc.", phone: "+1 555 101 2020", language: :en },
    { name: "Carlos Rodriguez", email: "carlos@designlab.mx", company: "Design Lab Mexico", phone: "+52 55 1234 5678", language: :es },
    { name: "Sarah Chen", email: "sarah@globalcorp.com", company: "Global Corp", language: :en }
  ]

  clients_data.each do |client_data|
    client = demo_user.clients.find_or_initialize_by(email: client_data[:email])
    client.assign_attributes(client_data)
    client.save!
  end

  puts "  #{demo_user.clients.count} demo clients created/updated"

  # Demo proposals
  alice = demo_user.clients.find_by(email: "alice@techstartup.io")
  carlos = demo_user.clients.find_by(email: "carlos@designlab.mx")
  sarah = demo_user.clients.find_by(email: "sarah@globalcorp.com")

  proposals_data = [
    {
      title: "Website Redesign",
      client: alice,
      scope: "Complete redesign of the company website including:\n\n- New homepage design\n- About and Services pages\n- Blog section\n- Contact form with validation",
      deliverables: "- Figma mockups for all pages\n- Responsive HTML/CSS/JS\n- WordPress theme\n- 2 rounds of revisions",
      terms: "50% deposit required to begin work. Final 50% due upon completion.",
      pricing_type: :fixed,
      amount: 8500.00,
      timeline_start: 2.weeks.from_now.to_date,
      timeline_end: 6.weeks.from_now.to_date,
      status: :draft
    },
    {
      title: "Mobile App Development",
      client: carlos,
      scope: "Desarrollo de aplicación móvil para iOS y Android usando React Native.\n\nFuncionalidades:\n- Autenticación de usuarios\n- Catálogo de productos\n- Carrito de compras\n- Pasarela de pagos",
      deliverables: "- Código fuente completo\n- Aplicación publicada en App Store y Google Play\n- Documentación técnica\n- 30 días de soporte post-lanzamiento",
      terms: "Pago en 3 fases: 30% inicio, 40% beta, 30% lanzamiento.",
      pricing_type: :hourly,
      hourly_rate: 125.00,
      estimated_hours: 200,
      timeline_start: 1.month.from_now.to_date,
      timeline_end: 4.months.from_now.to_date,
      status: :sent,
      sent_at: 2.days.ago
    },
    {
      title: "Brand Identity Package",
      client: sarah,
      scope: "Complete brand identity development including logo design, color palette, typography, and brand guidelines.",
      deliverables: "- Primary and secondary logo variations\n- Color palette with hex codes\n- Typography guidelines\n- Brand style guide (PDF)\n- All source files (AI, PSD)",
      terms: "Standard freelance terms apply. Unlimited revisions on logo concepts.",
      pricing_type: :fixed,
      amount: 3500.00,
      timeline_start: 1.week.from_now.to_date,
      timeline_end: 3.weeks.from_now.to_date,
      status: :viewed,
      sent_at: 5.days.ago,
      viewed_at: 3.days.ago
    },
    {
      title: "SEO Audit & Optimization",
      client: alice,
      scope: "Comprehensive SEO audit and implementation of recommended optimizations.",
      deliverables: "- Technical SEO audit report\n- Keyword research document\n- On-page optimization for 20 pages\n- Meta tags and schema markup",
      terms: "Payment due upon delivery of final report.",
      pricing_type: :fixed,
      amount: 2000.00,
      timeline_start: Date.today,
      timeline_end: 2.weeks.from_now.to_date,
      status: :accepted,
      sent_at: 2.weeks.ago,
      viewed_at: 12.days.ago,
      signature_name: "Alice Johnson",
      signature_ip: "192.168.1.100",
      signature_at: 10.days.ago
    }
  ]

  proposals_data.each do |proposal_data|
    proposal = demo_user.proposals.find_or_initialize_by(
      title: proposal_data[:title],
      client: proposal_data[:client]
    )
    proposal.assign_attributes(proposal_data)
    proposal.save!
  end

  puts "  #{demo_user.proposals.count} demo proposals created/updated"

  # Demo proposal templates
  templates_data = [
    {
      name: "Web Development Project",
      content: {
        "scope" => "Development of a custom web application including:\n\n- Frontend development\n- Backend API development\n- Database design\n- Third-party integrations",
        "deliverables" => "- Source code repository\n- Deployed application\n- Technical documentation\n- 30 days of bug fixes",
        "terms" => "50% deposit required to begin work. Final 50% due upon completion and deployment.",
        "pricing_type" => "hourly",
        "hourly_rate" => "125.00",
        "estimated_hours" => "80"
      }
    },
    {
      name: "Design & Branding Package",
      content: {
        "scope" => "Complete brand identity package including visual design, guidelines, and assets.",
        "deliverables" => "- Logo (multiple variations)\n- Color palette\n- Typography selection\n- Brand guidelines document\n- Social media templates",
        "terms" => "Unlimited revisions during the project. Final payment due before delivery of source files.",
        "pricing_type" => "fixed",
        "amount" => "3500.00"
      }
    },
    {
      name: "Consulting Engagement",
      content: {
        "scope" => "Strategic consulting and advisory services for your project.",
        "deliverables" => "- Weekly consultation calls\n- Written recommendations\n- Action plan document\n- Email support",
        "terms" => "Billed monthly in advance. Unused hours do not roll over.",
        "pricing_type" => "hourly",
        "hourly_rate" => "200.00",
        "estimated_hours" => "20"
      }
    }
  ]

  templates_data.each do |template_data|
    template = demo_user.proposal_templates.find_or_initialize_by(name: template_data[:name])
    template.assign_attributes(template_data)
    template.save!
  end

  puts "  #{demo_user.proposal_templates.count} demo templates created/updated"

  # Demo invoices
  accepted_proposal = demo_user.proposals.find_by(status: :accepted)

  invoices_data = [
    {
      client: alice,
      proposal: accepted_proposal,
      due_date: 2.weeks.from_now.to_date,
      status: :draft,
      notes: "Thank you for your business!",
      items: [
        { description: "SEO Audit", quantity: 1, rate: 1200.00 },
        { description: "Keyword Research", quantity: 1, rate: 400.00 },
        { description: "On-page Optimization (20 pages)", quantity: 20, rate: 20.00 }
      ]
    },
    {
      client: carlos,
      due_date: 1.month.from_now.to_date,
      status: :sent,
      sent_at: 3.days.ago,
      discount_type: :percent,
      discount_value: 10,
      deposit_percent: 50,
      tax_notes: "RFC: ACM123456ABC",
      notes: "Gracias por su preferencia.",
      items: [
        { description: "Desarrollo de aplicación móvil - Fase 1", quantity: 80, rate: 125.00 },
        { description: "Diseño de UI/UX", quantity: 20, rate: 100.00 }
      ]
    },
    {
      client: sarah,
      due_date: 1.week.ago.to_date,
      status: :paid,
      sent_at: 3.weeks.ago,
      notes: "Payment received - thank you!",
      items: [
        { description: "Logo Design", quantity: 1, rate: 1500.00 },
        { description: "Brand Guidelines Document", quantity: 1, rate: 800.00 },
        { description: "Social Media Templates", quantity: 5, rate: 150.00 }
      ]
    },
    {
      client: alice,
      due_date: 1.week.ago.to_date,
      status: :overdue,
      sent_at: 1.month.ago,
      discount_type: :fixed,
      discount_value: 200,
      notes: "Please remit payment at your earliest convenience.",
      items: [
        { description: "Website Maintenance (January)", quantity: 1, rate: 500.00 },
        { description: "Additional Development Hours", quantity: 8, rate: 125.00 }
      ]
    }
  ]

  invoices_data.each do |invoice_data|
    items = invoice_data.delete(:items)

    invoice = demo_user.invoices.find_or_initialize_by(
      client: invoice_data[:client],
      due_date: invoice_data[:due_date]
    )
    invoice.assign_attributes(invoice_data)
    invoice.save!

    # Create invoice items if new invoice
    if invoice.invoice_items.empty? && items.present?
      items.each do |item_data|
        invoice.invoice_items.create!(item_data)
      end
    end
  end

  puts "  #{demo_user.invoices.count} demo invoices created/updated"
end
