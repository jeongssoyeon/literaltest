package kr.co.literal.order;

import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Properties;
import java.util.UUID;

import javax.mail.Authenticator;
import javax.mail.Message;
import javax.mail.MessagingException;
import javax.mail.PasswordAuthentication;
import javax.mail.Session;
import javax.mail.Transport;
import javax.mail.internet.InternetAddress;
import javax.mail.internet.MimeMessage;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.ModelAndView;

import jakarta.servlet.http.HttpSession;
import kr.co.literal.member.MemberDAO;
import kr.co.literal.member.MemberDTO;
import kr.co.literal.product.ProductDAO;

import org.springframework.web.bind.annotation.PostMapping;

@Controller
@RequestMapping("/order")
public class OrderCont {

    public OrderCont() {
        System.out.println("-----OrderCont() 객체생성");
    }

    @Autowired
    OrderDAO orderDao;
    
    @Autowired
    MemberDAO memberDao;
    
    @Autowired
    ProductDAO productDao;

    @GetMapping("/orderDetail")
    public ModelAndView orderDetail(HttpSession session, @RequestParam(name = "selectedItems") List<String> selectedItems) 
    {
        ModelAndView mav = new ModelAndView("order/orderDetail");

        System.out.println("cont_selectedItems : " + selectedItems);
        
        String email = (String) session.getAttribute("email");
        if (email == null) {
            mav.addObject("msg1", "<p>세션이 만료되었거나 이메일 정보가 없습니다.</p>");
            mav.addObject("msg2", "<p><a href='/member/login'>로그인</a></p>");
            mav.setViewName("member/login");
            return mav;
        }

        
        if (selectedItems == null || selectedItems.isEmpty()) {
            mav.addObject("msg1", "<p>선택된 상품이 없습니다.</p>");
            mav.addObject("msg2", "<p><a href='/cart'>장바구니로 돌아가기</a></p>");
            mav.setViewName("error");
            return mav;
        }

        // 선택된 상품 정보를 세션에 저장
        session.setAttribute("selectedItems", selectedItems);
        
        // 선택된 상품 정보 가져오기
        Map<String, Object> params = new HashMap<>();
        params.put("email", email);
        params.put("selectedItems", selectedItems);
        // System.out.println("Fetching cart items with params: " + params);
        List<HashMap<String, Object>> cartItems = orderDao.getCartItems(params);
        // System.out.println("Fetched cart items: " + cartItems);

        int totalProductCount = cartItems.size();
        int totalProductAmount = cartItems.stream().mapToInt(item -> (int) item.get("sale_price")).sum();
        int totalOrderAmount = totalProductAmount;
        int expectedPoints = (int) (totalOrderAmount * 0.05); // 예상 적립금 계산
        int deliveryFee = (totalOrderAmount < 20000) ? 2500 : 0; // 배송비 계산

        String cartCode = orderDao.cart_code(email);

        mav.addObject("cartCode", cartCode);
        mav.addObject("email", email);

        mav.addObject("cartItems", cartItems);
        mav.addObject("totalProductCount", totalProductCount);
        mav.addObject("totalProductAmount", totalProductAmount);
        mav.addObject("totalOrderAmount", totalOrderAmount);
        mav.addObject("expectedPoints", expectedPoints);
        mav.addObject("deliveryFee", deliveryFee);

        // selectedItems 세션 저장
        //session.setAttribute("selectedItems", selectedItems);
        session.setAttribute("selectedCartItems", cartItems);

        // 사용자 보유 포인트 가져오기
        MemberDTO member = memberDao.getPoints(email);
        mav.addObject("userPoints", member.getPoints());
        
		/*
		 * System.out.println("mav: " + mav);
		 * 
		 * // 로그 출력 System.out.println("selectedItems: " + selectedItems);
		 * System.out.println("cartItems" + cartItems);
		 */

        return mav;
    }

    @Transactional
    @PostMapping("/orderProcess")
    public ModelAndView orderProcess(	@ModelAttribute OrderDTO orderDto, 
							    	    @RequestParam List<String> selectedItems, // 요청에서 selectedItems를 직접 받음
							    	    HttpSession session) 
    {
        ModelAndView mav = new ModelAndView();
        mav.setViewName("/order/orderProcess");

        String email = (String) session.getAttribute("email");
        if (email == null) {
            mav.addObject("msg1", "<p>세션이 만료되었거나 이메일 정보가 없습니다.</p>");
            mav.addObject("msg2", "<p><a href='/member/login'>로그인</a></p>");
            return mav;
        }

        // 사용자 보유 포인트 가져오기
        MemberDTO member = memberDao.getPoints(email);
        int userPoints = member.getPoints();
        int usedPoints = orderDto.getUsed_points();

        if (usedPoints > userPoints || usedPoints % 10 != 0 || userPoints < 500) {
            mav.addObject("msg1", "<p>사용할 수 없는 포인트 금액입니다. 500점 이상, 10점 단위로 사용 가능합니다.</p>");
            mav.addObject("msg2", "<p><a href='/order/orderDetail'>주문 페이지로 돌아가기</a></p>");
            return mav;
        }
        
        // 총 결제 금액 구하기
        int totalProductAmount = orderDao.totalamount(email);
        int totalOrderAmount = totalProductAmount - usedPoints;
        int savePoints = (int) (totalOrderAmount * 0.05);

        // 주문 데이터 삽입 전에 orderDto에 email 및 기타 필요한 정보 설정
        orderDto.setEmail(email);
        orderDto.setTotal_amount(totalOrderAmount);
        orderDto.setSave_points(savePoints);
        
        // 카트 코드 가져오기 (세션에서 직접 가져오기)
        String cartCode = (String) session.getAttribute("cart_code");
        if (cartCode == null) {
            cartCode = orderDao.cart_code(email);
        }

        // cartCode 유효성 검사 및 생성
        if (cartCode == null || !orderDao.isCartCodeValid(cartCode)) {
            mav.addObject("msg1", "<p>유효하지 않은 카트 코드입니다.</p>");
            mav.addObject("msg2", "<p><a href='/order/orderDetail'>주문 페이지로 돌아가기</a></p>");
            return mav;
        }

        orderDto.setCart_code(cartCode); // orderDto에 cart_code 설정

        // 결제 코드 생성 및 설정
        String paymentCode = generatePaymentCode();
        orderDto.setPayment_code(paymentCode);

        // 디버그 로그 추가
        //System.out.println("OrderDTO after setting codes: " + orderDto);

        // insertOrder 호출
        int result = orderDao.insertOrder(orderDto);

        if (result > 0) 
        {
            // 포인트 차감 및 적립
            memberDao.updatePoints(email, userPoints - usedPoints + savePoints);

            System.out.println("Calling order_sendMail method.");
            
            order_sendMail(orderDto);  // 이메일 전송 메서드 호출 추가
            System.out.println("order_sendMail method called.");

            // 외래 키 제약 조건 비활성화
            orderDao.disableForeignKeyChecks();

            try {
                // 선택된 상품만 장바구니서 삭제
                Map<String, Object> deleteParams = new HashMap<>();
                deleteParams.put("email", email);
                deleteParams.put("selectedItems", selectedItems);
                int deleteCount = orderDao.cartDelete(deleteParams);
                if (deleteCount == 0) {
                    throw new RuntimeException("선택된 상품을 장바구니에서 삭제하는 데 실패했습니다.");
                }
            } finally {
                // 외래 키 제약 조건 활성화
                orderDao.enableForeignKeyChecks();
            }

            // 결제 완료 페이지에 필요한 정보 추가
            mav.addObject("totalOrderAmount", totalOrderAmount);

            // 세션에서 selectedCartItems 가져오기
            List<HashMap<String, Object>> sessionCartItems = (List<HashMap<String, Object>>) session.getAttribute("selectedCartItems");
            mav.addObject("cartItems", sessionCartItems);

            // 주문 정보 추가
            Map<String, Object> orderInfo = new HashMap<>();
            orderInfo.put("payment_code", paymentCode);
            orderInfo.put("payment_date", new Date()); // 주문 날짜 추가
            orderInfo.put("recipient_name", orderDto.getRecipient_name());
            orderInfo.put("shipping_address", orderDto.getShipping_address());
            mav.addObject("orderInfo", orderInfo);

            // 세션에 cart_code 저장
            session.setAttribute("cart_code", cartCode);

            // 로그 출력
			/*
			 * System.out.println("Selected Items: " + selectedItems);
			 * System.out.println("Order Info: " + orderInfo);
			 * System.out.println("Session Cart Items: " + sessionCartItems);
			 * System.out.println("Payment Code: " + paymentCode);
			 */

            // 세션 데이터 초기화
            session.removeAttribute("selectedItems");
            session.removeAttribute("selectedCartItems");
            
            // 상품의 판매 상태 업데이트
            for (String productId : selectedItems) {
                productDao.updateAvailability(productId, 1); // 1: 판매 상태
            }

            mav.addObject("msg1", "<p>주문이 완료되었습니다.</p>");
            mav.addObject("msg2", "<p><a href='/order/orderDetail'>주문 내역 보기</a></p>");
        } else {
            mav.addObject("msg1", "<p>주문에 실패했습니다. 다시 시도해주세요.</p>");
            mav.addObject("msg2", "<p><a href='/order/orderDetail'>주문 페이지로 돌아가기</a></p>");
            return mav;
        }

        return mav;
    }

    // 결제 코드 생성 메서드
    private String generatePaymentCode() {
        SimpleDateFormat sdf = new SimpleDateFormat("yyyyMMddHHmmss");
        String datePart = sdf.format(new Date());
        String uuidPart = UUID.randomUUID().toString().replace("-", "").substring(0, 4);
        return datePart + uuidPart;
    }

    
    public void order_sendMail(OrderDTO orderDto) {
        // payment_code를 사용하여 cart_code 가져오기
        String cartCode = orderDao.getCartCodeByPaymentCode(orderDto.getPayment_code());

        // cart_code를 사용하여 주문내역서 메일 보내기
        List<HashMap<String, Object>> orderDesc = orderDao.orderDesc(cartCode);

        // 이메일 본문 내용 구성
        StringBuilder emailContent = new StringBuilder();
        emailContent.append("<html><body>");
        emailContent.append("<h1>주문이 완료되었습니다</h1>");
        emailContent.append("<p>주문번호: ").append(orderDto.getPayment_code()).append("</p>");
        emailContent.append("<hr>");
        emailContent.append("<p>결제페이지 확인해주세요.</p>");


        System.out.println("Email content created: " + emailContent.toString());

        try {
            String mailServer = "smtp.gmail.com"; // Gmail SMTP 서버
            Properties props = new Properties();
            props.put("mail.smtp.auth", "true");
            props.put("mail.smtp.starttls.enable", "true");
            props.put("mail.smtp.ssl.trust", "smtp.gmail.com");
            props.put("mail.smtp.host", mailServer);
            props.put("mail.smtp.port", "587");
            props.put("mail.smtp.ssl.protocols", "TLSv1.2");

            // Gmail 계정 인증 정보 (외부 파일이나 환경 변수로 관리 권장)
            final String username = "aekyung0896@gmail.com";
            final String password = "kphszxcjoerrbvyf";

            Session session = Session.getInstance(props, new Authenticator() {
                protected PasswordAuthentication getPasswordAuthentication() {
                    return new PasswordAuthentication(username, password);
                }
            });

            System.out.println("Sending email to: " + orderDto.getEmail());

            Message msg = new MimeMessage(session);
            msg.setFrom(new InternetAddress(username));
            msg.setRecipients(Message.RecipientType.TO, InternetAddress.parse(orderDto.getEmail()));
            msg.setSubject("주문 내역서");
            msg.setContent(emailContent.toString(), "text/html; charset=UTF-8");
            msg.setSentDate(new Date());
            Transport.send(msg);

            System.out.println("메일이 성공적으로 전송되었습니다.");
        } catch (MessagingException e) {
            System.out.println("결제 완료 이메일 전송 실패: " + e.getMessage());
            e.printStackTrace(); // 예외 로그 출력
        }
    }
}
