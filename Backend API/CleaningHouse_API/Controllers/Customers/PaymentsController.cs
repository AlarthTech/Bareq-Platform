// using Microsoft.AspNetCore.Mvc;
// using Microsoft.EntityFrameworkCore;
// using AutoMapper;
// using CleaningHouse_API.Data;
// using CleaningHouse_API.Models.Customers;
// using CleaningHouse_API.DTOs.Customers;

// namespace CleaningHouse_API.Controllers.Customers;

// [ApiController]
// [Route("api/[controller]")]
// public class PaymentsController : ControllerBase
// {
//     private readonly ApplicationDbContext _context;
//     private readonly IMapper _mapper;

    // public PaymentsController(ApplicationDbContext context, IMapper mapper)
    // {
    //     _context = context;
    //     _mapper = mapper;
    // }

    // // GET: api/Payments/getAllPayments
    // [HttpGet("getAllPayments")]
    // [ProducesResponseType(typeof(IEnumerable<PaymentDTO>), 200)]
    // public async Task<ActionResult<IEnumerable<PaymentDTO>>> GetPayments()
    // {
    //     var payments = await _context.Payments
    //         .Where(p => p.IsActive)
    //         .Include(p => p.Booking)
    //         .ToListAsync();
    //     return Ok(_mapper.Map<IEnumerable<PaymentDTO>>(payments));
    // }

    // // GET: api/Payments/getPaymentById/5
    // [HttpGet("getPaymentById/{id}")]
    // [ProducesResponseType(typeof(PaymentDTO), 200)]
    // [ProducesResponseType(404)]
    // public async Task<ActionResult<PaymentDTO>> GetPayment(int id)
    // {
    //     var payment = await _context.Payments
    //         .Where(p => p.Id == id && p.IsActive)
    //         .Include(p => p.Booking)
    //         .FirstOrDefaultAsync();

    //     if (payment == null)
    //     {
    //         return NotFound();
    //     }

    //     return Ok(_mapper.Map<PaymentDTO>(payment));
    // }

    // // GET: api/Payments/getPaymentsByBooking/5
    // [HttpGet("getPaymentsByBooking/{bookingId}")]
    // [ProducesResponseType(typeof(IEnumerable<PaymentDTO>), 200)]
    // public async Task<ActionResult<IEnumerable<PaymentDTO>>> GetPaymentsByBooking(int bookingId)
    // {
    //     var payments = await _context.Payments
    //         .Where(p => p.BookingId == bookingId && p.IsActive)
    //         .Include(p => p.Booking)
    //         .ToListAsync();
    //     return Ok(_mapper.Map<IEnumerable<PaymentDTO>>(payments));
    // }

    // // POST: api/Payments/createPayment
    // [HttpPost("createPayment")]
    // [ProducesResponseType(typeof(PaymentDTO), 201)]
    // [ProducesResponseType(400)]
    // public async Task<ActionResult<PaymentDTO>> PostPayment(CreatePaymentDTO createPaymentDTO)
    // {
    //     // Check if booking exists
    //     var booking = await _context.Bookings.FindAsync(createPaymentDTO.BookingId);
    //     if (booking == null)
    //     {
    //         return BadRequest("الحجز غير موجود");
    //     }

    //     var payment = _mapper.Map<Payment>(createPaymentDTO);
        
    //     // Set PaidAt if payment is successful
    //     if (createPaymentDTO.PaymentStatus == 1)
    //     {
    //         payment.PaidAt = DateTime.UtcNow;
    //     }

    //     _context.Payments.Add(payment);
    //     await _context.SaveChangesAsync();

    //     var paymentDTO = _mapper.Map<PaymentDTO>(payment);
    //     return CreatedAtAction(nameof(GetPayment), new { id = payment.Id }, paymentDTO);
    // }

    // // PUT: api/Payments/updatePayment/5
    // [HttpPut("updatePayment/{id}")]
    // [ProducesResponseType(204)]
    // [ProducesResponseType(400)]
    // [ProducesResponseType(404)]
    // public async Task<IActionResult> PutPayment(int id, UpdatePaymentDTO updatePaymentDTO)
    // {
    //     var payment = await _context.Payments.FindAsync(id);
    //     if (payment == null)
    //     {
    //         return NotFound();
    //     }

    //     _mapper.Map(updatePaymentDTO, payment);

    //     // Set PaidAt if payment status changed to successful
    //     if (updatePaymentDTO.PaymentStatus.HasValue && updatePaymentDTO.PaymentStatus.Value == 1 && payment.PaidAt == null)
    //     {
    //         payment.PaidAt = DateTime.UtcNow;
    //     }

    //     try
    //     {
    //         await _context.SaveChangesAsync();
    //     }
    //     catch (DbUpdateConcurrencyException)
    //     {
    //         if (!PaymentExists(id))
    //         {
    //             return NotFound();
    //         }
    //         else
    //         {
    //             throw;
    //         }
    //     }

    //     return NoContent();
    // }

    // // DELETE: api/Payments/deletePayment/5
    // [HttpDelete("deletePayment/{id}")]
    // [ProducesResponseType(204)]
    // [ProducesResponseType(404)]
    // public async Task<IActionResult> DeletePayment(int id)
    // {
    //     var payment = await _context.Payments.FindAsync(id);
    //     if (payment == null)
    //     {
    //         return NotFound();
    //     }

    //     payment.IsActive = false;
    //     await _context.SaveChangesAsync();

    //     return NoContent();
    // }

    // private bool PaymentExists(int id)
    // {
    //     return _context.Payments.Any(e => e.Id == id && e.IsActive);
    // }
// }

